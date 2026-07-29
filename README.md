<!-- prettier-ignore -->
<div align="center">

# personal-scripts

Small bash scripts I use daily.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](LICENSE)

</div>

## Scripts

### [`auto-searxng/`](auto-searxng/)

Sets up [SearXNG](https://docs.searxng.org) — a privacy-respecting metasearch engine — as a rootless Podman container managed by systemd. One command, no Docker, no root. Run the script and you have a search engine at `localhost:5039`.

### [`download-quran/`](download-quran/)

Downloads all 114 Quran surahs as MP3 files from [mp3quran.net](https://mp3quran.net). Give it any surah URL from the site, it figures out the rest — extracts the reciter name, creates a folder, and fetches every surah. Skips files you already have.

### [`video-copress/`](video-copress/)

Wraps ffmpeg to compress video files with sane defaults (CRF 23, libx264, medium preset). Handles codec-specific flags, resolution presets, and prints compression stats when done. Good for shrinking files before sharing.

## Usage

```bash
git clone https://github.com/EslamMohamed365/personal-scripts.git
cd personal-scripts
chmod +x */*.sh
```

Or run directly without cloning — each script's README has the curl command.
