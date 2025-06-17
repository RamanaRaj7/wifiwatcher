#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>
#import <signal.h>

// Version information
#define WIFIWATCHER_VERSION "1.0.0"

// Color definitions - matching the LoginWatcher theme
#define ANSI_RESET      "\033[0m"
#define ANSI_BOLD       "\033[1m"
#define ANSI_ACCENT     "\033[0;36m"     // Cyan for headings and highlights
#define ANSI_PRIMARY    "\033[0;36m"     // Cyan for primary elements
#define ANSI_SUCCESS    "\033[0;32m"     // Green for success/enabled states
#define ANSI_WARNING    "\033[0;33m"     // Yellow for warnings/optional states
#define ANSI_ERROR      "\033[0;31m"     // Red for errors/disabled states

// Function prototypes
void printHeader(NSString *title);
void printVersion(void);
void printUsage(void);
BOOL setupScriptFiles(void);
void colorLog(const char *color, NSString *prefix, NSString *message, NSString *details);
void cleanup(void);
void handleSignal(int signal);

// MARK: - Helper function for colorized logging
void colorLog(const char *color, NSString *prefix, NSString *message, NSString *details) {
    if (details) {
        NSLog(@"%s%-7s| %-24s | %s%s", color, [prefix UTF8String], [message UTF8String], [details UTF8String], ANSI_RESET);
    } else {
        NSLog(@"%s%-7s| %-24s |%s", color, [prefix UTF8String], [message UTF8String], ANSI_RESET);
    }
}

// MARK: - Pretty header for console output
void printHeader(NSString *title) {
    printf("\n%s%s╔════════════════════════════════════════════════════╗%s\n", ANSI_ACCENT, ANSI_BOLD, ANSI_RESET);
    printf("%s%s║ %-50s ║%s\n", ANSI_ACCENT, ANSI_BOLD, [title UTF8String], ANSI_RESET);
    printf("%s%s╚════════════════════════════════════════════════════╝%s\n\n", ANSI_ACCENT, ANSI_BOLD, ANSI_RESET);
}

// MARK: - Version and Usage
void printVersion() {
    printf("%swifiwatcher%s version %s%s%s\n", 
           ANSI_ACCENT,     // Blue for "wifiwatcher"
           ANSI_RESET,      // No color for "version"
           ANSI_SUCCESS,    // Green for the version number
           WIFIWATCHER_VERSION,
           ANSI_RESET);     // Reset color at the end
}

void printUsage() {
    printHeader(@"                WIFIWATCHER v1.0.0");
    
    printf("%s◇ DESCRIPTION%s\n", ANSI_ACCENT, ANSI_RESET);
    printf("  wifiwatcher detects Wi-Fi network changes and executes commands\n");
    printf("  when connecting to or disconnecting from networks.\n\n");
    
    printf("%s◇ USAGE%s\n", ANSI_ACCENT, ANSI_RESET);
    printf("  wifiwatcher [options]\n\n");
    
    printf("%s◇ OPTIONS%s\n", ANSI_ACCENT, ANSI_RESET);
    printf("  %s[1]%s --version     Print version information\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[2]%s --help        Print this help message\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[3]%s --setup       Create configuration file\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[4]%s --monitor     Start monitoring for Wi-Fi network changes\n\n", ANSI_PRIMARY, ANSI_RESET);
    
    printf("%s◇ CONFIGURATION%s\n", ANSI_ACCENT, ANSI_RESET);
    printf("  Add commands to ~/.wifiwatcher with condition tags:\n\n");
    printf("  %s[•]%s {on:connect}      Run when connecting to any network\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:disconnect}   Run when disconnecting from Wi-Fi completely\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:change}       Run when switching from one network to another\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifi:SSID}       Run when connecting to exact SSID\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wificontain:str} Run when SSID contains string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifinotcontain:str} Run when SSID does not contain string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifistart:str}   Run when SSID starts with string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifiend:str}     Run when SSID ends with string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {from:SSID}       Run when disconnecting/changing from specific SSID\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {to:SSID}         Run when connecting to specific SSID\n\n", ANSI_PRIMARY, ANSI_RESET);
    
    printf("  %sAdvanced Usage:%s\n", ANSI_SUCCESS, ANSI_RESET);
    printf("  %s[•]%s {from:wificontain:str}   Combined filters (e.g., from network containing 'str')\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {to:wifiend:str}         Combined filters (e.g., to network ending with 'str')\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {from:X}                 Standalone form triggers on any network change from X\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {from:X} {to:Y}          Triggers when switching directly from X to Y\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:change} {from:X} {to:Y}  Run when switching from network X to Y\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:disconnect} {from:X}  Run when disconnecting or switching from network X\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:connect} {from:X}     Run when connecting after previously being on network X\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {on:connect} {to:Y}       Run when connecting to network Y\n\n", ANSI_PRIMARY, ANSI_RESET);
    
    printf("  %sExamples:%s\n", ANSI_SUCCESS, ANSI_RESET);
    printf("    echo \"Connected to $WIFI_SSID\" {on:connect}          # Direct command\n");
    printf("    ~/bin/vpn-connect.sh {wifi:CompanyWiFi}              # Script for specific network\n");
    printf("    osascript -e 'display notification \"Public Wi-Fi\"' {wificontain:Public}  # Run AppleScript\n");
    printf("    /usr/local/bin/notify.sh {on:disconnect}             # Run on full disconnection only\n");
    printf("    ~/monitors.sh {on:disconnect} {from:KGP}             # Run when disconnected from KGP (including switches)\n");
    printf("    ~/monitorf.sh {from:wificontain:KGP}                 # Run when switching from KGP network\n");
    printf("    ~/monitorf.sh {to:wifiend:5G}                        # Run when connecting to network ending with 5G\n");
    printf("    ~/startup.sh {on:connect} {from:HomeWiFi}            # Run when connecting after being on HomeWiFi\n");
    printf("    ~/vpn.sh {on:change} {from:wificontain:Home} {to:wificontain:Work}  # Network switch\n");
    printf("    /opt/homebrew/opt/python@3.11/bin/python3.11 /Users/username/example.py {wifi:CompanyWiFi}     # can also execute python scripts\n\n");
    
    printf("%s◇ GETTING STARTED%s\n", ANSI_ACCENT, ANSI_RESET);
    printf("  %s[1]%s Run 'wifiwatcher --setup' to create configuration\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[2]%s Edit ~/.wifiwatcher to add your commands\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[3]%s Start the service with 'brew services start wifiwatcher'\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[4]%s Stop the service with 'brew services stop wifiwatcher'\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[5]%s Restart with 'brew services restart wifiwatcher'\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[6]%s Debug with 'brew services info wifiwatcher'\n\n", ANSI_PRIMARY, ANSI_RESET);
    printf("%s◇ MORE INFORMATION%s\n      Visit: %shttps://github.com/ramanaraj7/wifiwatcher%s\n\n", 
           ANSI_ACCENT,    
           ANSI_RESET,    
           ANSI_SUCCESS,   
           ANSI_RESET);    
    printf("%s──────────────────────────────────────────────────────%s\n\n", ANSI_PRIMARY, ANSI_RESET);
}

// MARK: - Setup Configuration File
BOOL setupScriptFiles() {
    printHeader(@"            WIFIWATCHER SETUP");
    
    NSString *homePath = NSHomeDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success = YES;
    
    // Create wifiwatcher configuration file
    NSString *wifiWatcherPath = [homePath stringByAppendingPathComponent:@".wifiwatcher"];
    if (![fileManager fileExistsAtPath:wifiWatcherPath]) {
        NSString *wifiWatcherContent = 
        @"#!/bin/bash\n"
        @"# WIFIWATCHER CONFIGURATION\n"
        @"# \n"
        @"# Format: /path/to/script {condition1} {condition2} ... \n"
        @"#  echo Connected to $WIFI_SSID {on:connect}      #example Direct command\n"
        @"# \n"
        @"# Available conditions (most can be combined using logical AND):\n"
        @"# {on:connect}      - Run when connecting to any network\n"
        @"# {on:disconnect}   - Run when disconnecting from Wi-Fi completely\n"
        @"# {on:change}       - Run when switching from one network to another\n"
        @"# {wifi:SSID}       - Run when connecting to specific SSID\n"
        @"# {wificontain:str} - Run when SSID contains string\n"
        @"# {wifinotcontain:str} - Run when SSID does not contain string\n"
        @"# {wifistart:str}   - Run when SSID starts with string\n"
        @"# {wifiend:str}     - Run when SSID ends with string\n"
        @"# {from:SSID}       - Run when disconnecting/changing from specific SSID\n"
        @"# {to:SSID}         - Run when connecting to specific SSID\n"
        @"# \n"
        @"# Add your scripts below(examples at https://github.com/ramanaraj7/wifiwatcher ):\n";
        
        success = [wifiWatcherContent writeToFile:wifiWatcherPath 
                                       atomically:YES 
                                         encoding:NSUTF8StringEncoding 
                                            error:&error];
        
        if (!success) {
            printf("%sError creating .wifiwatcher: %s%s\n", ANSI_ERROR, [error.localizedDescription UTF8String], ANSI_RESET);
            return NO;
        }
        
        // Make the configuration file executable
        [fileManager setAttributes:@{NSFilePosixPermissions:@(0755)} 
                     ofItemAtPath:wifiWatcherPath 
                            error:&error];
        
        printf("  %sCreated executable configuration: ~/.wifiwatcher%s\n", ANSI_SUCCESS, ANSI_RESET);
    } else {
        printf("  %sFile already exists: ~/.wifiwatcher%s\n", ANSI_WARNING, ANSI_RESET);
    }
    
    printf("\n%s%sSetup complete!%s\n\n", ANSI_BOLD, ANSI_SUCCESS, ANSI_RESET);
    printf("To use wifiwatcher run:\n");
    printf("  %sbrew services start wifiwatcher%s\n\n", ANSI_PRIMARY, ANSI_RESET);
    printf("Edit configuration file to customize your actions:\n");
    printf("  %s~/.wifiwatcher%s - Configure network triggers ('nano ~/.wifiwatcher' to edit)\n\n", ANSI_PRIMARY, ANSI_RESET);
    
    printf("%s──────────────────────────────────────────────────────%s\n", ANSI_PRIMARY, ANSI_RESET);
    
    return YES;
}

void cleanup(void) {
    colorLog(ANSI_ACCENT, @"SYSTEM", @"wifiwatcher shutting down", nil);
}

void handleSignal(int signal) {
    cleanup();
    exit(0);
}

@interface wifiwatcher : NSObject <CWEventDelegate>
@property (strong) CWWiFiClient *wifiClient;
@property (strong) NSString *lastSSID;
@property (strong) NSString *previousSSID;
@property (nonatomic) BOOL isConnected;
@property (nonatomic) BOOL wasConnected;
@property (nonatomic) NSInteger lastRSSI;
@property (strong) NSMutableArray *ssidHistory;
@property (nonatomic) BOOL debugMode;
@end

@implementation wifiwatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.wifiClient = [CWWiFiClient sharedWiFiClient];
        [self.wifiClient setDelegate:self];
        self.isConnected = NO;
        self.wasConnected = NO;
        self.lastRSSI = 0;
        self.ssidHistory = [NSMutableArray array];
        
        // Enable debug mode if DEBUG environment variable is set
        NSString *debugEnv = [[[NSProcessInfo processInfo] environment] objectForKey:@"DEBUG"];
        self.debugMode = (debugEnv != nil);

        NSError *error = nil;
        BOOL success = [self.wifiClient startMonitoringEventWithType:CWEventTypeSSIDDidChange error:&error];

        if (success) {
            colorLog(ANSI_SUCCESS, @"WIFI", @"Monitoring started", @"Listening for SSID changes");
            
            // Perform initial check of current WiFi state
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *currentSSID = [self getCurrentSSID];
                BOOL isConnected = ![currentSSID isEqualToString:@"(none)"];
                self.isConnected = isConnected;
                self.wasConnected = isConnected;
                self.lastSSID = currentSSID;
                
                // Record the initial SSID in history
                if (isConnected) {
                    [self.ssidHistory addObject:currentSSID];
                }
                
                // Get RSSI for initial connection
                CWInterface *interface = [self.wifiClient interface];
                NSInteger rssi = interface.rssiValue;
                self.lastRSSI = rssi;
                NSString *rssiString = (rssi == 0) ? @"unknown" : [NSString stringWithFormat:@"%ld", (long)rssi];
                
                if (isConnected) {
                    colorLog(ANSI_SUCCESS, @"WIFI", @"Initial connection", [NSString stringWithFormat:@"SSID: '%@' | RSSI: %@ dBm", currentSSID, rssiString]);
                    
                    // Execute scripts for initial connection
                    [self executeWifiWatcherScripts:currentSSID isConnect:YES initialCheck:YES];
                } else {
                    colorLog(ANSI_WARNING, @"WIFI", @"Not connected", @"No WiFi connection detected");
                }
            });
        } else {
            colorLog(ANSI_ERROR, @"ERROR", @"Failed to start monitoring", [NSString stringWithFormat:@"%@", error.localizedDescription]);
        }
    }
    return self;
}

- (void)dealloc {
    NSError *error = nil;
    [self.wifiClient stopMonitoringEventWithType:CWEventTypeSSIDDidChange error:&error];
    if (error) {
        colorLog(ANSI_WARNING, @"WARN", @"Failed to stop monitoring", [NSString stringWithFormat:@"%@", error.localizedDescription]);
    }
    [self.wifiClient setDelegate:nil];
}

- (NSString *)getCurrentSSID {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", @"ipconfig getsummary en0 | awk '/ SSID/ {print $NF}'"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    NSString *ssid = @"(none)";
    
    @try {
        [task launch];
        
        NSFileHandle *fileHandle = [pipe fileHandleForReading];
        NSData *data = [fileHandle readDataToEndOfFile];
        [fileHandle closeFile];
        
        [task waitUntilExit];

        if (data.length > 0) {
            ssid = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            ssid = [ssid stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            if (ssid.length == 0) {
                ssid = @"(none)";
            }
        }
    }
    @catch (NSException *exception) {
        colorLog(ANSI_ERROR, @"ERROR", @"Exception getting SSID", [NSString stringWithFormat:@"%@", exception.reason]);
    }
    
    return ssid;
}

- (NSString *)extractScriptPathFromLine:(NSString *)line conditions:(NSArray<NSString *> **)outConditions {
    NSMutableArray<NSString *> *conditions = [NSMutableArray array];
    NSString *scriptPath = line;
    
    // Find all condition markers - Expanded to include new conditions
    NSArray *conditionPrefixes = @[
        @"{wifi:", @"{wificontain:", @"{wifinotcontain:", @"{wifistart:", @"{wifiend:",
        @"{on:connect}", @"{on:disconnect}", @"{on:change}", @"{from:", @"{to:"
    ];
    
    for (NSString *conditionPrefix in conditionPrefixes) {
        NSRange searchRange = NSMakeRange(0, scriptPath.length);
        NSRange conditionRange;
        
        // Special handling for the fixed conditions that don't have a value parameter
        if ([conditionPrefix isEqualToString:@"{on:connect}"] || 
            [conditionPrefix isEqualToString:@"{on:disconnect}"] ||
            [conditionPrefix isEqualToString:@"{on:change}"]) {
            while ((conditionRange = [scriptPath rangeOfString:conditionPrefix options:0 range:searchRange]).location != NSNotFound) {
                // Add the full condition to the array
                [conditions addObject:conditionPrefix];
                
                // Remove the condition from the script path
                scriptPath = [scriptPath stringByReplacingOccurrencesOfString:conditionPrefix withString:@""];
                
                // Reset search range
                searchRange = NSMakeRange(0, scriptPath.length);
            }
            continue;
        }
        
        while ((conditionRange = [scriptPath rangeOfString:conditionPrefix options:0 range:searchRange]).location != NSNotFound) {
            // Extract the condition
            NSUInteger startIndex = conditionRange.location + conditionPrefix.length;
            NSRange endRange = [scriptPath rangeOfString:@"}" options:0 range:NSMakeRange(startIndex, scriptPath.length - startIndex)];
            
            if (endRange.location != NSNotFound) {
                NSString *conditionValue = [scriptPath substringWithRange:NSMakeRange(startIndex, endRange.location - startIndex)];
                NSString *fullCondition = [scriptPath substringWithRange:NSMakeRange(conditionRange.location, 
                                                                                   endRange.location - conditionRange.location + 1)];
                
                // Add the full condition to the array
                [conditions addObject:fullCondition];
                
                // Remove the condition from the script path
                scriptPath = [scriptPath stringByReplacingOccurrencesOfString:fullCondition withString:@""];
                
                // Reset search range
                searchRange = NSMakeRange(0, scriptPath.length);
            } else {
                // Malformed condition, move past it
                searchRange.location = conditionRange.location + conditionRange.length;
                searchRange.length = scriptPath.length - searchRange.location;
            }
        }
    }
    
    // Trim the script path
    scriptPath = [scriptPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (outConditions) {
        *outConditions = conditions;
    }
    
    return scriptPath;
}

// Helper method to evaluate a basic SSID condition
- (BOOL)evaluateSSIDCondition:(NSString *)condition against:(NSString *)ssid {
    if ([condition hasPrefix:@"wifi:"]) {
        NSString *requiredSSID = [condition substringWithRange:NSMakeRange(5, condition.length - 6)];
        return [ssid isEqualToString:requiredSSID]; // Case sensitive
    }
    else if ([condition hasPrefix:@"wificontain:"]) {
        NSString *substring = [condition substringWithRange:NSMakeRange(12, condition.length - 13)];
        return [ssid rangeOfString:substring].location != NSNotFound; // Case sensitive
    }
    else if ([condition hasPrefix:@"wifinotcontain:"]) {
        NSString *substring = [condition substringWithRange:NSMakeRange(15, condition.length - 16)];
        return [ssid rangeOfString:substring].location == NSNotFound; // Case sensitive
    }
    else if ([condition hasPrefix:@"wifistart:"]) {
        NSString *prefix = [condition substringWithRange:NSMakeRange(10, condition.length - 11)];
        return [ssid hasPrefix:prefix]; // Case sensitive
    }
    else if ([condition hasPrefix:@"wifiend:"]) {
        NSString *suffix = [condition substringWithRange:NSMakeRange(8, condition.length - 9)];
        return [ssid hasSuffix:suffix]; // Case sensitive
    }
    return NO;
}

// Method to evaluate nested 'from' conditions like {from:wificontain:str}
- (BOOL)evaluateFromCondition:(NSString *)condition againstSSID:(NSString *)previousSSID {
    // Extract the condition value (everything between {from: and the ending })
    if (![condition hasPrefix:@"{from:"]) {
        return NO;
    }
    
    NSString *fromValue = [condition substringWithRange:NSMakeRange(6, condition.length - 7)];
    
    // Check if this is a nested condition (e.g., wificontain:str)
    if ([fromValue hasPrefix:@"wifiend:"]) {
        NSString *suffix = [fromValue substringWithRange:NSMakeRange(8, fromValue.length - 8)];
        return [previousSSID hasSuffix:suffix];
    }
    else if ([fromValue hasPrefix:@"wifistart:"]) {
        NSString *prefix = [fromValue substringWithRange:NSMakeRange(10, fromValue.length - 10)];
        return [previousSSID hasPrefix:prefix];
    }
    else if ([fromValue hasPrefix:@"wificontain:"]) {
        NSString *substring = [fromValue substringWithRange:NSMakeRange(12, fromValue.length - 12)];
        return [previousSSID rangeOfString:substring].location != NSNotFound;
    }
    else if ([fromValue hasPrefix:@"wifinotcontain:"]) {
        NSString *substring = [fromValue substringWithRange:NSMakeRange(15, fromValue.length - 15)];
        return [previousSSID rangeOfString:substring].location == NSNotFound;
    }
    else if ([fromValue hasPrefix:@"wifi:"]) {
        NSString *requiredSSID = [fromValue substringWithRange:NSMakeRange(5, fromValue.length - 5)];
        return [previousSSID isEqualToString:requiredSSID];
    }
    
    // Simple exact match
    return [previousSSID isEqualToString:fromValue];
}

// Method to evaluate nested 'to' conditions like {to:wificontain:str}
- (BOOL)evaluateToCondition:(NSString *)condition againstSSID:(NSString *)currentSSID {
    // Extract the condition value (everything between {to: and the ending })
    if (![condition hasPrefix:@"{to:"]) {
        return NO;
    }
    
    NSString *toValue = [condition substringWithRange:NSMakeRange(4, condition.length - 5)];
    
    // Check if this is a nested condition (e.g., wificontain:str)
    if ([toValue hasPrefix:@"wifiend:"]) {
        NSString *suffix = [toValue substringWithRange:NSMakeRange(8, toValue.length - 8)];
        return [currentSSID hasSuffix:suffix];
    }
    else if ([toValue hasPrefix:@"wifistart:"]) {
        NSString *prefix = [toValue substringWithRange:NSMakeRange(10, toValue.length - 10)];
        return [currentSSID hasPrefix:prefix];
    }
    else if ([toValue hasPrefix:@"wificontain:"]) {
        NSString *substring = [toValue substringWithRange:NSMakeRange(12, toValue.length - 12)];
        return [currentSSID rangeOfString:substring].location != NSNotFound;
    }
    else if ([toValue hasPrefix:@"wifinotcontain:"]) {
        NSString *substring = [toValue substringWithRange:NSMakeRange(15, toValue.length - 15)];
        return [currentSSID rangeOfString:substring].location == NSNotFound;
    }
    else if ([toValue hasPrefix:@"wifi:"]) {
        NSString *requiredSSID = [toValue substringWithRange:NSMakeRange(5, toValue.length - 5)];
        return [currentSSID isEqualToString:requiredSSID];
    }
    
    // Simple exact match
    return [currentSSID isEqualToString:toValue];
}

// Debug method to help troubleshoot condition evaluation
- (void)debugCondition:(NSString *)condition againstSSID:(NSString *)ssid previousSSID:(NSString *)previousSSID {
    if (!self.debugMode) return;
    
    colorLog(ANSI_PRIMARY, @"DEBUG", @"Evaluating condition", condition);
    
    if ([condition hasPrefix:@"{to:"]) {
        BOOL result = [self evaluateToCondition:condition againstSSID:ssid];
        colorLog(result ? ANSI_SUCCESS : ANSI_WARNING, @"DEBUG", @"To condition result", 
               [NSString stringWithFormat:@"%@ against %@ = %@", condition, ssid, result ? @"TRUE" : @"FALSE"]);
    }
    else if ([condition hasPrefix:@"{from:"]) {
        BOOL result = [self evaluateFromCondition:condition againstSSID:previousSSID];
        colorLog(result ? ANSI_SUCCESS : ANSI_WARNING, @"DEBUG", @"From condition result", 
               [NSString stringWithFormat:@"%@ against %@ = %@", condition, previousSSID, result ? @"TRUE" : @"FALSE"]);
    }
    else if ([condition hasPrefix:@"{wifi:"] || 
             [condition hasPrefix:@"{wificontain:"] || 
             [condition hasPrefix:@"{wifinotcontain:"] || 
             [condition hasPrefix:@"{wifistart:"] || 
             [condition hasPrefix:@"{wifiend:"]) {
        BOOL result = [self evaluateSSIDCondition:[condition substringWithRange:NSMakeRange(1, condition.length - 2)] against:ssid];
        colorLog(result ? ANSI_SUCCESS : ANSI_WARNING, @"DEBUG", @"SSID condition result", 
               [NSString stringWithFormat:@"%@ against %@ = %@", condition, ssid, result ? @"TRUE" : @"FALSE"]);
    }
}

- (BOOL)checkCondition:(NSString *)condition againstSSID:(NSString *)ssid previousSSID:(NSString *)previousSSID isConnect:(BOOL)isConnect isChange:(BOOL)isChange isNetworkSwitch:(BOOL)isNetworkSwitch {
    // Debug output for troubleshooting
    [self debugCondition:condition againstSSID:ssid previousSSID:previousSSID];
    
    // Basic event conditions
    if ([condition isEqualToString:@"{on:connect}"]) {
        return isConnect;
    }
    else if ([condition isEqualToString:@"{on:disconnect}"]) {
        return !isConnect;
    }
    else if ([condition isEqualToString:@"{on:change}"]) {
        // FIX: on:change now only triggers on network switches, not connections/disconnections
        return isNetworkSwitch;
    }
    
    // From/To conditions
    else if ([condition hasPrefix:@"{from:"]) {
        return [self evaluateFromCondition:condition againstSSID:previousSSID];
    }
    else if ([condition hasPrefix:@"{to:"]) {
        return [self evaluateToCondition:condition againstSSID:ssid];
    }
    
    // Direct SSID conditions (implicitly for connect events)
    else if ([condition hasPrefix:@"{wifi:"]) {
        NSString *requiredSSID = [condition substringWithRange:NSMakeRange(6, condition.length - 7)];
        return isConnect && [ssid isEqualToString:requiredSSID]; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wificontain:"]) {
        NSString *substring = [condition substringWithRange:NSMakeRange(13, condition.length - 14)];
        return isConnect && [ssid rangeOfString:substring].location != NSNotFound; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wifinotcontain:"]) {
        NSString *substring = [condition substringWithRange:NSMakeRange(16, condition.length - 17)];
        return isConnect && [ssid rangeOfString:substring].location == NSNotFound; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wifistart:"]) {
        NSString *prefix = [condition substringWithRange:NSMakeRange(11, condition.length - 12)];
        return isConnect && [ssid hasPrefix:prefix]; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wifiend:"]) {
        NSString *suffix = [condition substringWithRange:NSMakeRange(9, condition.length - 10)];
        return isConnect && [ssid hasSuffix:suffix]; // Case sensitive
    }
    
    return NO;
}

- (void)executeScript:(NSString *)scriptPath reason:(NSString *)reason {
    // Log the script execution and reason on separate lines
    colorLog(ANSI_PRIMARY, @"SCRIPT", @"Executing", scriptPath);
    colorLog(ANSI_PRIMARY, @"REASON", @"Trigger condition", reason);
    
    // Create task and pipe
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    
    // Check if this is a direct command or a script file
    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
        // Check if file is executable
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:scriptPath error:nil];
        NSNumber *permissions = [attributes objectForKey:NSFilePosixPermissions];
        
        if (!([permissions unsignedShortValue] & 0100)) {
            colorLog(ANSI_WARNING, @"WARN", @"Script not executable", [NSString stringWithFormat:@"Path: %@", scriptPath]);
            
            // Try to make it executable
            NSError *chmodError = nil;
            if (![[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions:@(0755)} 
                                                 ofItemAtPath:scriptPath 
                                                        error:&chmodError]) {
                colorLog(ANSI_ERROR, @"ERROR", @"Cannot make script executable", 
                       [NSString stringWithFormat:@"Error: %@", chmodError.localizedDescription]);
                return;
            }
            
            colorLog(ANSI_SUCCESS, @"SCRIPT", @"Made script executable", scriptPath);
        }
        
        // It's a file path, use bash for better compatibility
        task.launchPath = @"/bin/bash";
        task.arguments = @[scriptPath];
    } else {
        // It's a command to execute
        task.launchPath = @"/bin/bash";
        task.arguments = @[@"-c", scriptPath];
    }
    
    // Set environment variables to provide context to the script
    NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
    NSString *ssid = self.lastSSID ?: @"(none)";
    [env setObject:ssid forKey:@"WIFI_SSID"];
    [env setObject:self.isConnected ? @"YES" : @"NO" forKey:@"WIFI_CONNECTED"];
    [env setObject:[NSString stringWithFormat:@"%ld", (long)self.lastRSSI] forKey:@"WIFI_RSSI"];
    [env setObject:reason forKey:@"WIFI_TRIGGER_REASON"]; // Add the reason to environment variables
    
    // Always provide previous SSID if available
    if (self.previousSSID) {
        [env setObject:self.previousSSID forKey:@"WIFI_PREVIOUS_SSID"];
    }
    [task setEnvironment:env];
    
    task.standardOutput = outPipe;
    task.standardError = errPipe;
    
    // Execute script asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            [task launch];
            
            // Capture output for better error reporting
            NSFileHandle *outHandle = [outPipe fileHandleForReading];
            NSFileHandle *errHandle = [errPipe fileHandleForReading];
            
            // Read data from handles (only using error data for reporting)
            [outHandle readDataToEndOfFile]; // Output data not used but needs to be read
            NSData *stderrData = [errHandle readDataToEndOfFile];
            
            [outHandle closeFile];
            [errHandle closeFile];
            
            [task waitUntilExit];
            
            int status = [task terminationStatus];
            if (status != 0) {
                // Log error output to help diagnose the issue
                NSString *errorOutput = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];
                if (errorOutput.length > 0) {
                    colorLog(ANSI_ERROR, @"SCRIPT", @"Error output", [errorOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
                }
                
                colorLog(ANSI_WARNING, @"SCRIPT", @"Exited with status", [NSString stringWithFormat:@"%d", status]);
            } else {
                // Only log successful completion, not the actual output
                colorLog(ANSI_SUCCESS, @"SCRIPT", @"Completed successfully", nil);
            }
        }
        @catch (NSException *exception) {
            colorLog(ANSI_ERROR, @"ERROR", @"Failed to execute script", [NSString stringWithFormat:@"%@", exception.reason]);
        }
    });
}

- (void)executeWifiWatcherScripts:(NSString *)currentSSID isConnect:(BOOL)isConnect initialCheck:(BOOL)initialCheck {
    // Get home directory
    NSString *homeDir = NSHomeDirectory();
    NSString *wifiWatcherPath = [homeDir stringByAppendingPathComponent:@".wifiwatcher"];
    
    // Modified: Redefine what triggers {on:change} - only actual network to network changes
    // Check if the SSID has changed (either direct switch or reconnect to different network)
    BOOL isChange = !initialCheck && 
                   self.previousSSID && 
                   ![self.previousSSID isEqualToString:currentSSID] && 
                   ![currentSSID isEqualToString:@"(none)"]; // SSID changed to another network (not disconnection)
    
    // Determine if this is a direct network switch event (changing from one network to another without disconnect)
    BOOL isNetworkSwitch = isChange && 
                          self.wasConnected && self.isConnected; // Both old and new states are connected
    
    // Check if the file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:wifiWatcherPath]) {
        colorLog(ANSI_WARNING, @"CONFIG", @"No .wifiwatcher file found", @"Run with --setup to create");
        return;
    }
    
    // Read the file
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:wifiWatcherPath 
                                                      encoding:NSUTF8StringEncoding 
                                                         error:&error];
    
    if (error) {
        colorLog(ANSI_ERROR, @"ERROR", @"Error reading .wifiwatcher", [NSString stringWithFormat:@"%@", error.localizedDescription]);
        return;
    }
    
    // Split the file into lines
    NSArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Process each line
    for (NSString *originalLine in lines) {
        // Skip empty lines or comments
        NSString *line = [originalLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (line.length == 0 || [line hasPrefix:@"#"]) {
            continue;
        }
        
        // Extract script path and conditions
        NSArray<NSString *> *conditions;
        NSString *scriptToExecute = [self extractScriptPathFromLine:line conditions:&conditions];
        
        // If there are no conditions, default to on:connect
        if (conditions.count == 0) {
            // Execute only if this is a connect event (default behavior)
            if (isConnect) {
                // Skip if this is an initial check and the script shouldn't run on startup
                if (initialCheck) {
                    continue;
                }
                
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reason = @"Default: on:connect (no explicit conditions)";
                [self executeScript:scriptToExecute reason:reason];
            }
            continue;
        }

        // Check for on:change with from/to conditions
        BOOL hasChangeCondition = NO;
        BOOL hasConnectCondition = NO;
        BOOL hasDisconnectCondition = NO;
        BOOL hasFromCondition = NO;
        BOOL hasToCondition = NO;
        NSMutableArray *matchingConditions = [NSMutableArray array];
        
        // First, identify what types of conditions we have
        for (NSString *condition in conditions) {
            if ([condition isEqualToString:@"{on:change}"]) {
                hasChangeCondition = YES;
            } else if ([condition isEqualToString:@"{on:connect}"]) {
                hasConnectCondition = YES;
            } else if ([condition isEqualToString:@"{on:disconnect}"]) {
                hasDisconnectCondition = YES;
            } else if ([condition hasPrefix:@"{from:"]) {
                hasFromCondition = YES;
            } else if ([condition hasPrefix:@"{to:"]) {
                hasToCondition = YES;
            }
        }
        
        // Handle standalone {from:...} condition (without an event trigger)
        // Treat it as equivalent to {on:change} {from:...}
        if (hasFromCondition && !hasChangeCondition && !hasConnectCondition && !hasDisconnectCondition && !initialCheck) {
            BOOL shouldExecute = NO;
            
            // Check if any from: condition matches the previous SSID
            for (NSString *condition in conditions) {
                if ([condition hasPrefix:@"{from:"]) {
                    if ([self evaluateFromCondition:condition againstSSID:self.previousSSID]) {
                        [matchingConditions addObject:condition];
                        shouldExecute = YES;
                    }
                }
            }
            
            // Check if there are also to: conditions that need to match
            if (shouldExecute && hasToCondition) {
                BOOL toMatched = NO;
                for (NSString *condition in conditions) {
                    if ([condition hasPrefix:@"{to:"]) {
                        if ([self evaluateToCondition:condition againstSSID:currentSSID]) {
                            [matchingConditions addObject:condition];
                            toMatched = YES;
                            break;
                        }
                    }
                }
                if (!toMatched) {
                    shouldExecute = NO;
                }
            }
            
            if (shouldExecute) {
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reasonString = [NSString stringWithFormat:@"Matched standalone {from:} condition: %@", 
                                        [matchingConditions componentsJoinedByString:@", "]];
                
                // Add SSID context to the reason
                if (self.isConnected && self.wasConnected) {
                    // Network switch
                    reasonString = [reasonString stringByAppendingFormat:@" | Switched from: %@ to: %@", 
                                  self.previousSSID ?: @"(unknown)", currentSSID];
                } else if (self.isConnected) {
                    // Connection
                    reasonString = [reasonString stringByAppendingFormat:@" | Connected to: %@", currentSSID];
                } else {
                    // Disconnection
                    reasonString = [reasonString stringByAppendingFormat:@" | Disconnected from: %@", 
                                  self.previousSSID ?: @"(unknown)"];
                }
                
                [self executeScript:scriptToExecute reason:reasonString];
                continue; // Skip the other condition checks
            }
        }
        
        // Handle {on:connect} with {from:...} condition
        else if (isConnect && hasConnectCondition && hasFromCondition && !hasChangeCondition) {
            BOOL shouldExecute = YES;
            [matchingConditions addObject:@"{on:connect}"];
            
            // Verify the from: condition matches the previous network
            if (hasFromCondition) {
                BOOL fromMatched = NO;
                for (NSString *condition in conditions) {
                    if ([condition hasPrefix:@"{from:"]) {
                        if ([self evaluateFromCondition:condition againstSSID:self.previousSSID]) {
                            [matchingConditions addObject:condition];
                            fromMatched = YES;
                            break; // One from match is sufficient
                        }
                    }
                }
                if (!fromMatched) {
                    shouldExecute = NO;
                    matchingConditions = [NSMutableArray array]; // Clear matching conditions
                }
            }
            
            if (shouldExecute) {
                // Also check if there are to: conditions
                if (hasToCondition) {
                    BOOL toMatched = NO;
                    for (NSString *condition in conditions) {
                        if ([condition hasPrefix:@"{to:"]) {
                            if ([self evaluateToCondition:condition againstSSID:currentSSID]) {
                                [matchingConditions addObject:condition];
                                toMatched = YES;
                                break; // One to match is sufficient
                            }
                        }
                    }
                    if (!toMatched) {
                        shouldExecute = NO;
                        matchingConditions = [NSMutableArray array]; // Clear matching conditions
                    }
                }
            }
            
            if (shouldExecute) {
                // Skip initial check unless explicitly configured
                if (initialCheck) {
                    continue;
                }
                
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reasonString = [NSString stringWithFormat:@"Matched conditions: %@", 
                                        [matchingConditions componentsJoinedByString:@", "]];
                
                // Add SSID context to the reason
                reasonString = [reasonString stringByAppendingFormat:@" | Connected to: %@ after being on: %@", 
                              currentSSID, self.previousSSID ?: @"(unknown)"];
                
                [self executeScript:scriptToExecute reason:reasonString];
                continue; // Skip other condition checks
            }
        }
        
        // Modified: Special case for {on:change} + optional {from:} and/or {to:} conditions
        // {on:change} now triggers on ANY network change, direct switches or disconnect/reconnect to different network
        else if (hasChangeCondition && isChange) { // Changed to use isChange instead of isNetworkSwitch
            BOOL shouldExecute = YES;
            
            // If there are from/to conditions, they must match
            if (hasFromCondition || hasToCondition) {
                // Check from conditions
                if (hasFromCondition) {
                    BOOL fromMatched = NO;
                    for (NSString *condition in conditions) {
                        if ([condition hasPrefix:@"{from:"]) {
                            if ([self evaluateFromCondition:condition againstSSID:self.previousSSID]) {
                                [matchingConditions addObject:condition];
                                fromMatched = YES;
                                break; // One from match is sufficient
                            }
                        }
                    }
                    if (!fromMatched) {
                        shouldExecute = NO;
                    }
                }
                
                // Check to conditions
                if (shouldExecute && hasToCondition) {
                    BOOL toMatched = NO;
                    for (NSString *condition in conditions) {
                        if ([condition hasPrefix:@"{to:"]) {
                            if ([self evaluateToCondition:condition againstSSID:currentSSID]) {
                                [matchingConditions addObject:condition];
                                toMatched = YES;
                                break; // One to match is sufficient
                            }
                        }
                    }
                    if (!toMatched) {
                        shouldExecute = NO;
                    }
                }
            }
            
            // If conditions matched or there were no from/to conditions
            if (shouldExecute) {
                [matchingConditions addObject:@"{on:change}"];
                
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reasonString = [NSString stringWithFormat:@"Matched conditions: %@", 
                                        [matchingConditions componentsJoinedByString:@", "]];
                
                // Add SSID context to the reason - network switches or reconnects with different SSID
                if (isNetworkSwitch) {
                    reasonString = [reasonString stringByAppendingFormat:@" | Switched directly from: %@ to: %@", 
                                  self.previousSSID ?: @"(unknown)", currentSSID];
                } else {
                    reasonString = [reasonString stringByAppendingFormat:@" | Changed from: %@ to: %@", 
                                  self.previousSSID ?: @"(unknown)", currentSSID];
                }
                
                [self executeScript:scriptToExecute reason:reasonString];
                continue; // Skip the other condition checks
            }
        }
        
        // Check for on:disconnect with from condition
        // Plain {on:disconnect} should only trigger on complete disconnection
        // {on:disconnect} {from:X} should trigger on both disconnection from X and switching from X
        else if ((!isConnect || (isNetworkSwitch && hasFromCondition)) && hasDisconnectCondition) {
            BOOL shouldExecute = YES;
            [matchingConditions addObject:@"{on:disconnect}"];
            
            // If there are from conditions, they must match
            if (hasFromCondition) {
                BOOL fromMatched = NO;
                for (NSString *condition in conditions) {
                    if ([condition hasPrefix:@"{from:"]) {
                        if ([self evaluateFromCondition:condition againstSSID:self.previousSSID]) {
                            [matchingConditions addObject:condition];
                            fromMatched = YES;
                            break; // One from match is sufficient
                        }
                    }
                }
                if (!fromMatched) {
                    shouldExecute = NO;
                    matchingConditions = [NSMutableArray array]; // Clear matching conditions
                }
            } else {
                // Plain {on:disconnect} without {from:} should ONLY execute on complete disconnection
                if (isNetworkSwitch) {
                    shouldExecute = NO;
                    matchingConditions = [NSMutableArray array]; // Clear matching conditions
                }
            }
            
            if (shouldExecute) {
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reasonString = [NSString stringWithFormat:@"Matched conditions: %@", 
                                        [matchingConditions componentsJoinedByString:@", "]];
                
                // Add SSID context to the reason
                if (isNetworkSwitch) {
                    reasonString = [reasonString stringByAppendingFormat:@" | Switched from: %@ to: %@", 
                                  self.previousSSID ?: @"(unknown)", currentSSID];
                } else {
                    reasonString = [reasonString stringByAppendingFormat:@" | Disconnected from: %@", 
                                  self.previousSSID ?: @"(unknown)"];
                }
                
                [self executeScript:scriptToExecute reason:reasonString];
                continue; // Skip the other condition checks
            }
        }
        
        // Check for on:connect with to condition or direct wifi conditions
        else if (isConnect && (hasConnectCondition || hasToCondition || [self hasWifiCondition:conditions])) {
            BOOL shouldExecute = NO;
            matchingConditions = [NSMutableArray array]; // Clear matching conditions
            
            // Check if we have {on:connect}
            if (hasConnectCondition) {
                [matchingConditions addObject:@"{on:connect}"];
                shouldExecute = YES;
            }
            
            // Check to conditions
            if (hasToCondition) {
                BOOL toMatched = NO;
                for (NSString *condition in conditions) {
                    if ([condition hasPrefix:@"{to:"]) {
                        if ([self evaluateToCondition:condition againstSSID:currentSSID]) {
                            [matchingConditions addObject:condition];
                            toMatched = YES;
                            shouldExecute = YES;
                        }
                    }
                }
            }
            
            // Check direct wifi conditions
            for (NSString *condition in conditions) {
                if ([condition hasPrefix:@"{wifi:"] || 
                    [condition hasPrefix:@"{wificontain:"] || 
                    [condition hasPrefix:@"{wifinotcontain:"] || 
                    [condition hasPrefix:@"{wifistart:"] || 
                    [condition hasPrefix:@"{wifiend:"]) {
                    if ([self checkCondition:condition againstSSID:currentSSID previousSSID:self.previousSSID isConnect:YES isChange:isChange isNetworkSwitch:isNetworkSwitch]) {
                        [matchingConditions addObject:condition];
                        shouldExecute = YES;
                    }
                }
            }
            
            // If we have explicit connect conditions but no match, don't run
            if ((hasConnectCondition || hasToCondition || [self hasWifiCondition:conditions]) && matchingConditions.count == 0) {
                shouldExecute = NO;
            }
            
            // Execute on initial check for both explicit {on:connect} conditions 
            // and direct WiFi conditions like {wifi:SSID}
            if (initialCheck && shouldExecute) {
                // Always execute for initial check when conditions match
                // No skipping needed - let all matching conditions run
            }
            
            if (shouldExecute) {
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                NSString *reasonString = [NSString stringWithFormat:@"Matched conditions: %@", 
                                        [matchingConditions componentsJoinedByString:@", "]];
                
                // Add SSID context to the reason
                reasonString = [reasonString stringByAppendingFormat:@" | Connected to: %@", currentSSID];
                if (initialCheck) {
                    reasonString = [reasonString stringByAppendingString:@" (Initial check)"];
                }
                
                [self executeScript:scriptToExecute reason:reasonString];
            }
        }
    }
}

- (BOOL)hasWifiCondition:(NSArray<NSString *> *)conditions {
    for (NSString *condition in conditions) {
        if ([condition hasPrefix:@"{wifi:"] || 
            [condition hasPrefix:@"{wificontain:"] || 
            [condition hasPrefix:@"{wifinotcontain:"] || 
            [condition hasPrefix:@"{wifistart:"] || 
            [condition hasPrefix:@"{wifiend:"]) {
            return YES;
        }
    }
    return NO;
}

- (void)executeWifiWatcherScripts:(NSString *)currentSSID isConnect:(BOOL)isConnect {
    [self executeWifiWatcherScripts:currentSSID isConnect:isConnect initialCheck:NO];
}

- (void)ssidDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName {
    // Get current SSID
    NSString *ssid = [self getCurrentSSID];
    
    // Get RSSI from interface
    CWInterface *interface = [self.wifiClient interface];
    NSInteger rssi = interface.rssiValue;
    self.lastRSSI = rssi;
    NSString *rssiString = (rssi == 0) ? @"unknown" : [NSString stringWithFormat:@"%ld", (long)rssi];

    // Check if this is a connection or disconnection
    BOOL isConnected = ![ssid isEqualToString:@"(none)"];
    BOOL wasConnected = self.isConnected;
    BOOL connectionStateChanged = (isConnected != wasConnected);
    
    // Store previous SSID and connection state before updating
    self.wasConnected = wasConnected;
    if (wasConnected) {
        self.previousSSID = self.lastSSID;
    }
    
    // Update current connection state
    self.isConnected = isConnected;

    // Only log and process on actual SSID change
    if (![ssid isEqualToString:self.lastSSID] || connectionStateChanged) {
        // Store the new SSID
        self.lastSSID = ssid;
        
        // Add to SSID history (useful for tracking network switching)
        if (isConnected) {
            [self.ssidHistory addObject:ssid];
            // Keep history manageable
            if (self.ssidHistory.count > 10) {
                [self.ssidHistory removeObjectAtIndex:0];
            }
        }

        if ([ssid isEqualToString:@"(none)"]) {
            colorLog(ANSI_WARNING, @"WIFI", @"Disconnected", [NSString stringWithFormat:@"Interface: %@ | Previous: %@", 
                                                             interfaceName, self.previousSSID ?: @"(none)"]);
        } else if (wasConnected && isConnected) {
            colorLog(ANSI_SUCCESS, @"WIFI", @"Network changed", [NSString stringWithFormat:@"From: '%@' to: '%@' | RSSI: %@ dBm", 
                                                              self.previousSSID ?: @"(none)", ssid, rssiString]);
                } else {
            colorLog(ANSI_SUCCESS, @"WIFI", @"Connected", [NSString stringWithFormat:@"SSID: '%@' | RSSI: %@ dBm", ssid, rssiString]);
        }
        
        // Execute scripts from .wifiwatcher with connection state
        [self executeWifiWatcherScripts:ssid isConnect:isConnected];
    }
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Set up signal handling
        signal(SIGINT, handleSignal);
        signal(SIGTERM, handleSignal);
        
        // Default to showing help - changed from monitor mode
        BOOL shouldMonitor = NO;
        
        // Check for command line arguments
        if (argc > 1) {
            NSString *arg = [NSString stringWithUTF8String:argv[1]];
            
            if ([arg isEqualToString:@"--version"]) {
                printVersion();
                return 0;
            } else if ([arg isEqualToString:@"--help"]) {
                printUsage();
                return 0;
            } else if ([arg isEqualToString:@"--setup"]) {
                return setupScriptFiles() ? 0 : 1;
            } else if ([arg isEqualToString:@"--monitor"]) {
                shouldMonitor = YES;
            } else {
                fprintf(stderr, "%sUnknown option: %s%s\n", ANSI_ERROR, argv[1], ANSI_RESET);
                printUsage();
                return 1;
            }
        } else {
            // When no arguments are provided, show help instead of monitoring
            printUsage();
            return 0;
        }
        
        if (shouldMonitor) {
            printHeader(@"               WIFIWATCHER MONITOR");
            colorLog(ANSI_ACCENT, @"SYSTEM", [NSString stringWithFormat:@"wifiwatcher v%s starting up", WIFIWATCHER_VERSION], nil);
            colorLog(ANSI_ACCENT, @"SYSTEM", @"Listening for Wi-Fi events", nil);
            printf("%s──────────────────────────────────────────────────────%s\n", ANSI_PRIMARY, ANSI_RESET);
            
            // Create and retain the monitor instance (needed for delegate callbacks)
            __unused wifiwatcher *monitor = [[wifiwatcher alloc] init];
            [[NSRunLoop currentRunLoop] run];
        }
    }
    return 0;
}