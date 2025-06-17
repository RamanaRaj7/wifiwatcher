# WiFi Watcher

A macOS utility that monitors Wi-Fi network changes and executes user-defined scripts when connecting to or disconnecting from networks.

## Features

- Monitors Wi-Fi SSID changes in real-time
- Executes custom scripts based on network conditions:
  - When connecting to any network
  - When disconnecting from any network
  - When connecting to specific networks (exact match, contains, starts with, ends with)
- Provides environmental variables to scripts (SSID, connection status, signal strength)
- Easy setup with example configuration and scripts

## Installation

### Using Homebrew

```bash
brew install ramanaraj7/tap/wifiwatcher
```

### Manual Installation

1. Clone the repository
2. Run `make`
3. Copy the binary to your preferred location

## Usage

### Setup

Run the setup command to create example configuration and scripts:

```bash
wifiwatcher --setup
```

This creates:
- `~/.wifiwatcher` configuration file
- Example scripts in `~/scripts/`

### Configuration

Edit `~/.wifiwatcher` to define your triggers and scripts:

```
# Format: /path/to/script {condition1} {condition2} ...

# Available conditions:
# {on:connect}      - Run when connecting to any network
# {on:disconnect}   - Run when disconnecting from any network
# {wifi:SSID}       - Run when connecting to specific SSID
# {wificontain:str} - Run when SSID contains string
# {wifistart:str}   - Run when SSID starts with string
# {wifiend:str}     - Run when SSID ends with string

# Examples:
~/scripts/home.sh {wifi:HomeNetwork}
~/scripts/vpn.sh {wificontain:Public} {on:connect}
/usr/local/bin/notify.sh {on:disconnect}
```

### Running

Start the service using Homebrew:

```bash
brew services start wifiwatcher
```

Or run manually:

```bash
wifiwatcher --monitor
```

### Other Commands

```bash
wifiwatcher --help       # Show help message
wifiwatcher --version    # Show version information
```

## Environment Variables

Scripts receive these environment variables:

- `WIFI_SSID` - Current SSID (network name)
- `WIFI_CONNECTED` - YES or NO
- `WIFI_RSSI` - Signal strength in dBm
- `WIFI_PREVIOUS_SSID` - Previous network name (on disconnect)
- `WIFI_TIMESTAMP` - Current timestamp (UTC)
- `WIFI_USER` - Current username

## License

MIT License 