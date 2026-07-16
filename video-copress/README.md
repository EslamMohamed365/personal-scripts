# compress-video

A bash script for compressing video files using [ffmpeg](https://ffmpeg.org/). Supports multiple codecs, resolution presets, and fine-grained quality control.

## Prerequisites

- `ffmpeg` and `ffprobe` must be installed and available in your `PATH`

```bash
# Debian/Ubuntu
sudo apt install ffmpeg

# macOS
brew install ffmpeg
```

## Usage

```bash
./compress-video.sh [OPTIONS] <input_file>
```

### Basic examples

```bash
# Compress with defaults (CRF 23, libx264, medium preset)
./compress-video.sh video.mp4

# Lower quality for smaller file
./compress-video.sh -c 28 -p fast video.mp4

# Downscale to 720p
./compress-video.sh -r 720 -c 28 video.mov

# Custom scale with lower audio bitrate
./compress-video.sh -s 640x480 -a 96k video.avi
```

### Options

| Flag | Description | Default |
| ------ | ------------- | --------- |
| `-o, --output FILE` | Output file path | `<input>_compressed.<ext>` |
| `-c, --crf VALUE` | CRF quality (0-51, lower = better) | `23` |
| `-p, --preset NAME` | Encoding preset (`ultrafast` to `veryslow`) | `medium` |
| `-v, --video-codec NAME` | Video codec | `libx264` |
| `-a, --audio-bitrate BR` | Audio bitrate | `128k` |
| `-ac, --audio-codec NAME` | Audio codec | `aac` |
| `-s, --scale WxH` | Scale output (e.g. `1280x720`) | keep original |
| `-r, --resolution PRESET` | Resolution preset: `4k`, `2k`, `1080`, `720`, `480` | keep original |

> [!NOTE]
> The `-r` flag overrides `-s` if both are specified.

### Supported codecs

The script handles codec-specific arguments automatically:

- **libx264 / libx265** -- CRF + preset
- **libvpx-vp9** -- CRF + unconstrained bitrate
- **libaom-av1** -- CRF + unconstrained bitrate
- Any other codec passed through to ffmpeg as-is

## Output

After compression, the script reports the output file size and compression ratio:

```
[2025-07-16 12:00:00] INFO: Compression complete
[2025-07-16 12:00:00] INFO: Output:       video_compressed.mp4
[2025-07-16 12:00:00] INFO: Compressed:   45.2MiB (ratio: 32.1%)
```
