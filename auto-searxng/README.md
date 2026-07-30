<!-- prettier-ignore -->
<div align="center">

<img src="searxng.svg" alt="SearXNG logo" align="center" height="96" />

# install-searxng

One-command setup for [SearXNG](https://docs.searxng.org) as a rootless Podman Quadlet systemd service.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](LICENSE)

[Overview](#overview) &bull; [Prerequisites](#prerequisites) &bull; [Installation](#installation) &bull; [Usage](#usage) &bull; [Configuration](#configuration) &bull; [Default search engine](#set-as-default-search-engine) &bull; [Troubleshooting](#troubleshooting)

</div>

## Overview

A single bash script that installs and runs SearXNG as a rootless Podman container managed by systemd Quadlet. No Docker. No root. No manual configuration files.

The script creates a Quadlet container definition, cleans up any previous installation, and starts the service -- all in one shot.

**What it does:**

- Checks for required dependencies (`podman`, `systemctl`)
- Enables user-level systemd lingering if needed
- Generates a Quadlet `.container` file at `~/.config/containers/systemd/searxng.container`
- Starts and enables the `searxng.service` systemd user unit
- Verifies the service is running before exiting

## Prerequisites

- Linux with systemd
- [Podman](https://podman.io/) installed
- User-level systemd session (`loginctl enable-linger $USER` if not already active)

## Installation

Clone the repository and run the script:

```bash
git clone https://github.com/EslamMohamed365/personal-scripts.git
cd personal-scripts/auto-searxng
chmod +x install-searxng.sh
./install-searxng.sh
```

Or run directly without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/EslamMohamed365/personal-scripts/main/auto-searxng/install-searxng.sh | bash
```

## Usage

```bash
./install-searxng.sh [OPTIONS]
```

**Options:**

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help message |
| `-p`, `--port NUM` | Port to expose SearXNG on (default: `5039`) |

**Examples:**

```bash
# Install with default settings
./install-searxng.sh

# Use a custom port
./install-searxng.sh --port 8888
```

Once running, access SearXNG at:

```
http://localhost:5039
```

## Configuration

The script writes a Quadlet container file to:

```
~/.config/containers/systemd/searxng.container
```

To customize the SearXNG instance further (engines, settings, themes), mount a custom `settings.yml` by editing the Quadlet file after installation:

```ini
[Container]
Volume=$HOME/.config/searxng/settings.yml:/etc/searxng/settings.yml:ro
```

### Systemd management

```bash
# Check service status
systemctl --user status searxng

# View logs
journalctl --user -u searxng -f

# Restart after config changes
systemctl --user restart searxng

# Stop the service
systemctl --user stop searxng

# Disable autostart
systemctl --user disable searxng
```

### Container auto-updates

The Quadlet file includes `AutoUpdate=registry`. For automatic background updates, enable the Podman auto-update timer:

```bash
systemctl --user enable --now podman-auto-update.timer
```

Or trigger updates manually:

```bash
podman auto-update
```

## Set as default search engine

SearXNG exposes an OpenSearch XML descriptor that browsers can use to add it as a search engine.

### Automatic detection

1. Open `http://localhost:5039` in your browser
2. Most browsers will automatically detect the OpenSearch link and offer to add SearXNG as a search engine
3. Confirm the prompt to add it

### Manual setup by browser

<details>
<summary><strong>Firefox</strong></summary>

1. Open `http://localhost:5039`
2. Right-click the address bar and select **Add Search Engine**
3. Select **SearXNG** from the list

Alternatively:

1. Go to `about:preferences#search`
2. Scroll to **Search Shortcuts** and click **Add**
3. Enter `http://localhost:5039` and save

</details>

<details>
<summary><strong>Chrome / Chromium</strong></summary>

1. Open `http://localhost:5039`
2. Right-click the address bar and select **Manage search engines** > **Add**
3. Fill in:
   - **Search engine**: `SearXNG`
   - **Shortcut**: `searxng`
   - **URL**: `http://localhost:5039/search?q=%s`
4. Click **Save**

</details>

<details>
<summary><strong>Brave</strong></summary>

1. Open `http://localhost:5039`
2. Right-click the address bar and select **Manage search engines** > **Add**
3. Fill in:
   - **Search engine**: `SearXNG`
   - **Shortcut**: `searxng`
   - **URL**: `http://localhost:5039/search?q=%s`
4. Click **Save**

</details>

<details>
<summary><strong>Edge</strong></summary>

1. Open `http://localhost:5039`
2. Right-click the address bar and select **Manage search engines** > **Add**
3. Fill in:
   - **Search engine**: `SearXNG`
   - **Keyword**: `searxng`
   - **URL**: `http://localhost:5039/search?q=%s`
4. Click **Save**

</details>

<details>
<summary><strong>Safari</strong></summary>

1. Open `http://localhost:5039`
2. Go to **Safari** > **Settings** > **Search**
3. Click **Manage Search Engines...**
4. Click **Add...** and enter:
   - **Name**: `SearXNG`
   - **URL**: `http://localhost:5039/search?q=%s`
5. Click **Save**

</details>

> [!TIP]
> Replace `localhost` with your server's IP or hostname if accessing SearXNG from multiple machines on your network.

## Troubleshooting

> [!CAUTION]
> If the service fails to start, check the logs first:
>
> ```bash
> journalctl --user -u searxng -e
> ```

**"systemd user session is not available"**

Enable lingering for your user:

```bash
loginctl enable-linger $USER
```

**"Failed to start searxng.service"**

- Verify Podman can pull images: `podman pull docker.io/searxng/searxng:latest`
- Check if port is already in use: `ss -tlnp | grep 5039`
- Inspect full logs: `journalctl --user -u searxng --no-pager`

**Service runs but SearXNG is unreachable**

- Confirm the container is running: `podman ps`
- Verify port mapping: `podman port searxng`
- Check firewall rules if accessing from another machine

**Reinstalling from scratch**

```bash
systemctl --user stop searxng
systemctl --user disable searxng
podman rm -f searxng
rm -f ~/.config/containers/systemd/searxng.container
systemctl --user daemon-reload

# Then run the installer again
./install-searxng.sh
```
