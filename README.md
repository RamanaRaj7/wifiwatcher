# wifiwatcher

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/RamanaRaj7/wifiwatcher)

if you find it intresting a ⭐️ on GitHub would mean a lot!

A macOS utility that monitors Wi-Fi network changes and executes user-defined scripts when connecting to or disconnecting from networks.

## Features

- Monitors Wi-Fi SSID changes in real-time
- Detects connections, disconnections, and network switches
- Executes custom scripts based on powerful condition matching:
  - When connecting to any network
  - When disconnecting completely from Wi-Fi
  - When switching from one network to another
  - When connecting to specific networks using pattern matching
  - When transitioning from one specific network to another
- Provides context-aware environment variables to scripts
- Simple configuration with flexible condition syntax
- Advanced condition combinations for complex triggers

## Installation

### Using Homebrew

```bash
brew install ramanaraj7/tap/wifiwatcher
```

Start the service using Homebrew:
```bash
brew services start wifiwatcher
```

### Manual Installation

Clone the repository:
```bash
git clone https://github.com/ramanaraj7/wifiwatcher.git
cd wifiwatcher
```

Compile the application:
```bash
clang -framework Foundation -framework CoreWLAN -fobjc-arc -o wifiwatcher wifiwatcher.m
```

Copy the binary to a location in your PATH:
```bash
sudo cp wifiwatcher /usr/local/bin/
```

Create a LaunchAgent to run at login:
```bash
mkdir -p ~/Library/LaunchAgents
cp homebrew.mxcl.wifiwatcher.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.wifiwatcher.plist
```

Run the setup to create your configuration file:
```bash
wifiwatcher --setup
```

## Usage

### Setup

Run the setup command to create your configuration file:

```bash
wifiwatcher --setup
```

This creates:
- `~/.wifiwatcher` configuration file with example configurations

### Configuration

Edit `~/.wifiwatcher` to define your triggers and scripts:

```
# Format: /path/to/script {condition1} {condition2} ...

# Basic conditions:
# {on:connect}         - Run when connecting to any network
# {on:disconnect}      - Run when disconnecting from Wi-Fi completely
# {on:change}          - Run when switching from one network to another

# SSID matching conditions:
# {wifi:SSID}          - Run when connecting to exact SSID
# {wificontain:str}    - Run when SSID contains string
# {wifinotcontain:str} - Run when SSID does not contain string  
# {wifistart:str}      - Run when SSID starts with string
# {wifiend:str}        - Run when SSID ends with string

# Transition conditions:
# {from:SSID}          - Run when disconnecting/changing from specific SSID
# {to:SSID}            - Run when connecting to specific SSID

# Examples:
echo "Connected to $WIFI_SSID" {on:connect}          # Direct command
~/bin/vpn-connect.sh {wifi:CompanyWiFi}              # Script for specific network
osascript -e 'display notification "Public Wi-Fi"' {wificontain:Public}  # Run AppleScript
/usr/local/bin/notify.sh {on:disconnect}             # Run on disconnection only
~/monitors.sh {on:disconnect} {from:KGP}             # Run when disconnected from KGP
~/monitorf.sh {from:wificontain:KGP}                 # Run when switching from KGP network
~/monitorf.sh {on:change} {from:KGP} {to:KGP-5G}     # Run when switching between specific networks
```

### Advanced Condition Usage

WiFiWatcher supports advanced condition combinations:

```
# Combined filters:
{from:wificontain:str}   - From network containing string
{to:wifiend:str}         - To network ending with string

# Standalone transitions:
{from:X}                 - Any network change from X
{from:X} {to:Y}          - Switching directly from X to Y

# Event-specific transitions:
{on:change} {from:X} {to:Y}  - Switch from network X to Y
{on:disconnect} {from:X}     - Disconnect or switch from network X
{on:connect} {from:X}        - Connect after previously being on network X
```

### Running

Start the service using Homebrew:

```bash
brew services start wifiwatcher
```

### Service Management

```bash
brew services start wifiwatcher     # Start the service
brew services stop wifiwatcher      # Stop the service
brew services restart wifiwatcher   # Restart the service
brew services info wifiwatcher      # Check service status
```

For manual installation, use launchctl:
```bash
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.wifiwatcher.plist    # Start
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.wifiwatcher.plist  # Stop
```

### Other Commands

```bash
wifiwatcher --help       # Show help message
wifiwatcher --version    # Show version information
wifiwatcher --setup      # Create configuration file
wifiwatcher --monitor    # Can be used to test out manualy and debug
```

## Environment Variables

Scripts receive these environment variables which can be used inside ~/.wifiwatcher:

- `WIFI_SSID` - Current SSID or '(none)' if disconnected
- `WIFI_CONNECTED` - YES or NO
- `WIFI_RSSI` - Signal strength in dBm
- `WIFI_PREVIOUS_SSID` - Previous SSID (when available)
- `WIFI_TIMESTAMP` - Current timestamp (UTC)
- `WIFI_TRIGGER_REASON` - Describes why the script was executed

## Special Behavior Notes

- `{on:change}` triggers when switching between networks (directly or after disconnection)
- Direct WiFi conditions (like `{wifi:SSID}`) trigger on initial connection and reconnections
- Combined conditions (like `{on:connect} {from:X}`) require all parts to match
- Scripts can be direct shell commands or paths to executable files or other scripts

## License

MIT License 
