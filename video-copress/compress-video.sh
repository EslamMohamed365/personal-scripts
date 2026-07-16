#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")

# Defaults
DEFAULT_CRF=23
DEFAULT_PRESET="medium"
DEFAULT_VIDEO_CODEC="libx264"
DEFAULT_AUDIO_BITRATE="128k"
DEFAULT_AUDIO_CODEC="aac"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() {
  log "ERROR: $*" >&2
  exit 1
}
info() { log "INFO: $*"; }

check_deps() {
  command -v ffmpeg >/dev/null 2>&1 || error "ffmpeg not found. Install it first."
  command -v ffprobe >/dev/null 2>&1 || error "ffprobe not found. Install it first."
}

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] <input_file>

Compress a video file using ffmpeg.

Options:
    -o, --output FILE       Output file path (default: <input>_compressed.<ext>)
    -c, --crf VALUE         CRF quality 0-51, lower=better (default: $DEFAULT_CRF)
    -p, --preset NAME       Encoding preset: ultrafast..veryslow (default: $DEFAULT_PRESET)
    -v, --video-codec NAME  Video codec (default: $DEFAULT_VIDEO_CODEC)
    -a, --audio-bitrate BR  Audio bitrate (default: $DEFAULT_AUDIO_BITRATE)
    -ac, --audio-codec NAME Audio codec (default: $DEFAULT_AUDIO_CODEC)
    -s, --scale WxH         Scale output (e.g. 1280x720)
    -r, --resolution PRESET Resolution preset: 4k, 2k, 1080, 720, 480 (default: keep original)
    -h, --help              Show this help

Examples:
    $SCRIPT_NAME video.mp4
    $SCRIPT_NAME -c 28 -p fast -o small.mp4 video.mp4
    $SCRIPT_NAME -r 720 -c 28 video.mov
    $SCRIPT_NAME -s 640x480 -a 96k video.avi
EOF
}

get_resolution_scale() {
  local preset="$1"
  case "$preset" in
  4k) echo "3840x2160" ;;
  2k) echo "2560x1440" ;;
  1080) echo "1920x1080" ;;
  720) echo "1280x720" ;;
  480) echo "640x480" ;;
  *) error "Unknown resolution preset: $preset (use 4k, 2k, 1080, 720, or 480)" ;;
  esac
}

format_size() {
  local bytes="$1"
  numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null || echo "${bytes} bytes"
}

get_original_info() {
  local input="$1"
  local raw_size duration

  raw_size=$(stat -c%s "$input" 2>/dev/null || echo "")

  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input" 2>/dev/null || echo "0")
  if [ -n "$duration" ] && [ "$duration" != "0" ]; then
    duration=$(printf "%.1f%ss" "$duration")
  else
    duration="unknown"
  fi

  echo "${raw_size:-unknown}"
  echo "$duration"
}

main() {
  local input=""
  local output=""
  local crf="$DEFAULT_CRF"
  local preset="$DEFAULT_PRESET"
  local video_codec="$DEFAULT_VIDEO_CODEC"
  local audio_bitrate="$DEFAULT_AUDIO_BITRATE"
  local audio_codec="$DEFAULT_AUDIO_CODEC"
  local scale=""
  local resolution=""

  while [ $# -gt 0 ]; do
    case "$1" in
    -o | --output)
      output="$2"
      shift 2
      ;;
    -c | --crf)
      crf="$2"
      shift 2
      ;;
    -p | --preset)
      preset="$2"
      shift 2
      ;;
    -v | --video-codec)
      video_codec="$2"
      shift 2
      ;;
    -a | --audio-bitrate)
      audio_bitrate="$2"
      shift 2
      ;;
    -ac | --audio-codec)
      audio_codec="$2"
      shift 2
      ;;
    -s | --scale)
      scale="$2"
      shift 2
      ;;
    -r | --resolution)
      resolution="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) error "Unknown option: $1" ;;
    *)
      input="$1"
      shift
      ;;
    esac
  done

  [ -z "$input" ] && {
    usage
    error "No input file specified"
  }
  [ -f "$input" ] || error "Input file not found: $input"
  check_deps

  # Resolution preset overrides scale
  if [ -n "$resolution" ]; then
    scale=$(get_resolution_scale "$resolution")
  fi

  # Default output path
  if [ -z "$output" ]; then
    local basename="${input%.*}"
    local ext="${input##*.}"
    output="${basename}_compressed.${ext}"
  fi

  [ -f "$output" ] && error "Output file already exists: $output (remove it or specify a different name)"

  # Get original file info
  local orig_size orig_duration
  read -r orig_size orig_duration <<< "$(get_original_info "$input")"

  info "Input:        $input"
  info "Output:       $output"
  info "Original:     $( [ "$orig_size" = "unknown" ] && echo "unknown" || format_size "$orig_size" ) ($orig_duration)"
  info "CRF:          $crf"
  info "Preset:       $preset"
  info "Video codec:  $video_codec"
  info "Audio codec:  $audio_codec"
  info "Audio bitrate:$audio_bitrate"
  [ -n "$scale" ] && info "Scale:        $scale"

  # Build ffmpeg command
  local -a cmd=(ffmpeg -i "$input" -y)

  # Video filter
  local vf=""
  if [ -n "$scale" ]; then
    vf="scale=${scale/x/:}"
  fi

  # Video codec args
  case "$video_codec" in
  libx264 | libx265)
    cmd+=(-c:v "$video_codec" -crf "$crf" -preset "$preset")
    ;;
  libvpx-vp9)
    cmd+=(-c:v libvpx-vp9 -crf "$crf" -b:v 0)
    ;;
  libaom-av1)
    cmd+=(-c:v libaom-av1 -crf "$crf" -b:v 0)
    ;;
  *)
    cmd+=(-c:v "$video_codec")
    ;;
  esac

  # Scale filter
  if [ -n "$vf" ]; then
    cmd+=(-vf "$vf")
  fi

  # Audio codec args
  cmd+=(-c:a "$audio_codec" -b:a "$audio_bitrate")

  # Misc
  cmd+=(-movflags +faststart -loglevel info -stats)

  cmd+=("$output")

  info "Running: ${cmd[*]}"

  if "${cmd[@]}"; then
    local new_raw_size
    new_raw_size=$(stat -c%s "$output" 2>/dev/null || echo "")

    local ratio="N/A"
    if [ -n "$orig_size" ] && [ -n "$new_raw_size" ] && [ "$new_raw_size" -gt 0 ] 2>/dev/null; then
      ratio=$(awk "BEGIN {printf \"%.1f%%\", ($new_raw_size/$orig_size)*100}")
    fi

    info "Compression complete"
    info "Output:       $output"
    info "Compressed:   $( [ -z "$new_raw_size" ] && echo "unknown" || format_size "$new_raw_size" ) (ratio: $ratio)"
  else
    rm -f "$output"
    error "ffmpeg failed"
  fi
}

main "$@"
