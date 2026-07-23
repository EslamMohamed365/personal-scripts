# compress-video

Thin wrapper around [ffmpeg](https://ffmpeg.org/). Sets CRF 23, libx264, and medium preset by default. Handles codec-specific args and prints compression stats after each run.

## Prerequisites

`ffmpeg` and `ffprobe` must be in `PATH`. Both ship together in most package managers:

```bash
# Debian/Ubuntu
sudo apt install ffmpeg

# Fedora
sudo dnf install ffmpeg

# Arch Linux
sudo pacman -S ffmpeg

# macOS
brew install ffmpeg

# Windows (winget)
winget install Gyan.FFmpeg

# Windows (scoop)
scoop install ffmpeg
```

## Usage

```bash
chmod -x compress-video.sh
./compress-video.sh [OPTIONS] <input_file>
```

### Examples

```bash
# Defaults (CRF 23, libx264, medium preset)
./compress-video.sh video.mp4

# Smaller file, faster encode
./compress-video.sh -c 28 -p fast video.mp4

# Downscale to 720p
./compress-video.sh -r 720 -c 28 video.mov

# Custom scale, lower audio bitrate
./compress-video.sh -s 640x480 -a 96k video.avi
```

### Options

| Flag | Description | Default |
| ---- | ----------- | ------- |
| `-o, --output FILE` | Output file path | `<input>_compressed.<ext>` |
| `-c, --crf VALUE` | CRF quality (0-51, lower = better) | `23` |
| `-p, --preset NAME` | Encoding preset (`ultrafast` to `veryslow`) | `medium` |
| `-v, --video-codec NAME` | Video codec | `libx264` |
| `-a, --audio-bitrate BR` | Audio bitrate | `128k` |
| `-ac, --audio-codec NAME` | Audio codec | `aac` |
| `-s, --scale WxH` | Scale output (e.g. `1280x720`) | keep original |
| `-r, --resolution PRESET` | Resolution preset: `4k`, `2k`, `1080`, `720`, `480` | keep original |

> [!NOTE]
> `-r` overrides `-s` when both are set.
>
> **Windows:** This script requires a bash-compatible shell. Use Git Bash, WSL, or MSYS2.

### Codec handling

The script passes the right flags for each encoder:

- **libx264 / libx265** -- CRF + preset
- **libvpx-vp9** -- CRF + unconstrained bitrate
- **libaom-av1** -- CRF + unconstrained bitrate
- Anything else goes straight to ffmpeg unchanged

### Safety

The script refuses to overwrite an existing output file. Remove or rename the target first.

## Output

After encoding, the script prints the compressed file size and compression ratio:

```
[2025-07-16 12:00:00] INFO: Compression complete
[2025-07-16 12:00:00] INFO: Output:       video_compressed.mp4
[2025-07-16 12:00:00] INFO: Compressed:   45.2MiB (ratio: 32.1%)
```
