<!-- prettier-ignore -->
<div align="center">

<img src="searxng.svg" alt="SearXNG logo" align="center" height="96" />

# install-searxng

One-command setup for [SearXNG](https://docs.searxng.org) as a rootless Podman Quadlet systemd service.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](LICENSE)

[Overview](#overview) &bull; [Prerequisites](#prerequisites) &bull; [Installation](#installation) &bull; [Usage](#usage) &bull; [Configuration](#configuration) &bull; [Default search engine](#set-as-default-search-engine) &bull; [Container Auto-Updates](#container-auto-updates) &bull; [Troubleshooting](#troubleshooting)

</div>

## Overview

A single bash script that installs and runs SearXNG as a rootless Podman container managed by systemd Quadlet. No Docker. No root. No manual configuration required.

The script generates default configuration settings, sets up a Quadlet container definition, enables daily automatic updates, and starts the service -- all in one shot.

**What it does:**

- Checks for required dependencies (`podman`, `systemctl`, `openssl`)
- Checks that user-level systemd lingering is active (fails with instructions if not)
- Generates a default configuration at `~/.config/searxng/settings.yml` (with a random secret key) if not present
- Generates a Quadlet `.container` file at `~/.config/containers/systemd/searxng.container`
- Starts and enables the `searxng.service` systemd user unit
- Enables `podman-auto-update.timer` by default for daily background container updates
- Verifies the service is running before exiting

## Prerequisites

- Linux with systemd
- [Podman](https://podman.io/) installed
- `openssl` (used to generate a secure secret key for SearXNG)
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
| `-p`, `--port NUM` | Host port to expose SearXNG on (default: `5039`) |

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

### SearXNG settings

The script automatically generates a starter configuration file at:

```
~/.config/searxng/settings.yml
```

You can customize your instance (active search engines, themes, language options) by editing this file directly. Changes will persist across container restarts and updates.

### Quadlet file

The Quadlet container definition is placed at:

```
~/.config/containers/systemd/searxng.container
```

### Systemd management

```bash
# Check service status
systemctl --user status searxng

# View logs
journalctl --user -u searxng -f

# Restart service after editing settings.yml
systemctl --user restart searxng

# Stop the service
systemctl --user stop searxng

# Disable autostart
systemctl --user disable searxng
```

## Container Auto-Updates

Daily automatic container updates are enabled by default during setup using systemd's `podman-auto-update.timer`.

**How it works:**

1. **Labeling** -- the Quadlet file includes `AutoUpdate=registry`, which adds the `io.containers.autoupdate=registry` label to the container.
2. **Scheduling** -- systemd triggers `podman-auto-update.service` once a day via `podman-auto-update.timer`.
3. **Execution** -- Podman checks the registry for a newer image, pulls it if available, gracefully restarts `searxng.service`, and prunes old unused images to save disk space.

**Useful management commands:**

```bash
# Check auto-update timer status
systemctl --user status podman-auto-update.timer

# Run a manual update check immediately
podman auto-update

# Disable automatic updates
systemctl --user disable --now podman-auto-update.timer
```

## Set as default search engine

SearXNG exposes an OpenSearch XML descriptor that browsers can use to add it as a search engine.

### Automatic detection

1. Open `http://localhost:5039` in your browser
2. Most browsers will automatically detect the OpenSearch link and offer to add SearXNG as a search engine
3. Confirm the prompt to add it

### Manual setup by browser

All browsers use the same search URL: `http://localhost:5039/search?q=%s`

| Browser | Steps |
|---------|-------|
| **Firefox** | Right-click address bar > **Add Search Engine** > select SearXNG. Or: `about:preferences#search` > **Search Shortcuts** > **Add**. |
| **Chrome / Chromium** | Right-click address bar > **Manage search engines** > **Add**. Set **Shortcut** to `searxng`. |
| **Brave** | Right-click address bar > **Manage search engines** > **Add**. Set **Shortcut** to `searxng`. |
| **Edge** | Right-click address bar > **Manage search engines** > **Add**. Set **Keyword** to `searxng`. |
| **Safari** | **Safari** > **Settings** > **Search** > **Manage Search Engines...** > **Add...** |

> [!TIP]
> Replace `localhost` with your server's IP or hostname if accessing SearXNG from multiple machines on your network.

## Stopping & Uninstalling

```bash
# Stop the service
systemctl --user stop searxng

# Disable autostart on boot
systemctl --user disable searxng

# Remove container and images
podman rm -f searxng
podman rmi docker.io/searxng/searxng:latest

# Delete configuration files
rm -rf ~/.config/searxng ~/.config/containers/systemd/searxng.container

# Reload systemd
systemctl --user daemon-reload
```

To also disable auto-updates:

```bash
systemctl --user disable --now podman-auto-update.timer
```

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
rm -f ~/.config/containers/systemd/searxng.container
rm -rf ~/.config/searxng
systemctl --user daemon-reload

# Then run the installer again
./install-searxng.sh
```
