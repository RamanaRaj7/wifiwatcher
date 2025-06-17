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
    printf("  %s[•]%s {on:disconnect}   Run when disconnecting from any network\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifi:SSID}       Run when connecting to exact SSID\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wificontain:str} Run when SSID contains string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifistart:str}   Run when SSID starts with string\n", ANSI_PRIMARY, ANSI_RESET);
    printf("  %s[•]%s {wifiend:str}     Run when SSID ends with string\n\n", ANSI_PRIMARY, ANSI_RESET);
    
    printf("  %sExamples:%s\n", ANSI_SUCCESS, ANSI_RESET);
    printf("    echo \"Connected to $WIFI_SSID\" {on:connect}          # Direct command\n");
    printf("    ~/bin/vpn-connect.sh {wifi:CompanyWiFi}              # Script for specific network\n");
    printf("    osascript -e 'display notification \"Public Wi-Fi\"' {wificontain:Public}  # Run AppleScript\n");
    printf("    /usr/local/bin/notify.sh {on:disconnect}             # Run on any disconnect\n");
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
        @"# Available conditions:\n"
        @"# {on:connect}      - Run when connecting to any network\n"
        @"# {on:disconnect}   - Run when disconnecting from any network\n"
        @"# {wifi:SSID}       - Run when connecting to specific SSID\n"
        @"# {wificontain:str} - Run when SSID contains string\n"
        @"# {wifistart:str}   - Run when SSID starts with string\n"
        @"# {wifiend:str}     - Run when SSID ends with string\n"
        @"# \n"
        @"# Add your scripts below:\n";
        
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
@property (nonatomic) NSInteger lastRSSI;
@end

@implementation wifiwatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.wifiClient = [CWWiFiClient sharedWiFiClient];
        [self.wifiClient setDelegate:self];
        self.isConnected = NO;
        self.lastRSSI = 0;

        NSError *error = nil;
        BOOL success = [self.wifiClient startMonitoringEventWithType:CWEventTypeSSIDDidChange error:&error];

        if (success) {
            colorLog(ANSI_SUCCESS, @"WIFI", @"Monitoring started", @"Listening for SSID changes");
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
    
    // Find all condition markers
    NSArray *conditionTypes = @[
        @"{wifi:", @"{wificontain:", @"{wifistart:", @"{wifiend:",
        @"{on:connect}", @"{on:disconnect}"
    ];
    
    for (NSString *conditionType in conditionTypes) {
        NSRange searchRange = NSMakeRange(0, scriptPath.length);
        NSRange conditionRange;
        
        // Special handling for the fixed conditions that don't have a value parameter
        if ([conditionType isEqualToString:@"{on:connect}"] || [conditionType isEqualToString:@"{on:disconnect}"]) {
            while ((conditionRange = [scriptPath rangeOfString:conditionType options:0 range:searchRange]).location != NSNotFound) {
                // Add the full condition to the array
                [conditions addObject:conditionType];
                
                // Remove the condition from the script path
                scriptPath = [scriptPath stringByReplacingOccurrencesOfString:conditionType withString:@""];
                
                // Reset search range
                searchRange = NSMakeRange(0, scriptPath.length);
            }
            continue;
        }
        
        while ((conditionRange = [scriptPath rangeOfString:conditionType options:0 range:searchRange]).location != NSNotFound) {
            // Extract the condition
            NSUInteger startIndex = conditionRange.location + conditionRange.length;
            NSRange endRange = [scriptPath rangeOfString:@"}" options:0 range:NSMakeRange(startIndex, scriptPath.length - startIndex)];
            
            if (endRange.location != NSNotFound) {
                NSString *conditionValue = [scriptPath substringWithRange:NSMakeRange(startIndex, endRange.location - startIndex)];
                NSString *fullCondition = [scriptPath substringWithRange:NSMakeRange(conditionRange.location, 
                                                                                    endRange.location - conditionRange.location + 1)];
                
                // Add the full condition to the array
                [conditions addObject:[NSString stringWithFormat:@"%@%@}", conditionType, conditionValue]];
                
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

- (BOOL)checkCondition:(NSString *)condition againstSSID:(NSString *)ssid isConnect:(BOOL)isConnect {
    // All comparisons are case sensitive by default
    
    if ([condition isEqualToString:@"{on:connect}"]) {
        return isConnect;
    }
    else if ([condition isEqualToString:@"{on:disconnect}"]) {
        return !isConnect;
    }
    else if ([condition hasPrefix:@"{wifi:"]) {
        NSString *requiredSSID = [condition substringWithRange:NSMakeRange(6, condition.length - 7)];
        return [ssid isEqualToString:requiredSSID]; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wificontain:"]) {
        NSString *substring = [condition substringWithRange:NSMakeRange(13, condition.length - 14)];
        return [ssid rangeOfString:substring].location != NSNotFound; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wifistart:"]) {
        NSString *prefix = [condition substringWithRange:NSMakeRange(11, condition.length - 12)];
        return [ssid hasPrefix:prefix]; // Case sensitive
    }
    else if ([condition hasPrefix:@"{wifiend:"]) {
        NSString *suffix = [condition substringWithRange:NSMakeRange(9, condition.length - 10)];
        return [ssid hasSuffix:suffix]; // Case sensitive
    }
    
    return NO;
}

- (void)executeWifiWatcherScripts:(NSString *)currentSSID isConnect:(BOOL)isConnect {
    // Get home directory
    NSString *homeDir = NSHomeDirectory();
    NSString *wifiWatcherPath = [homeDir stringByAppendingPathComponent:@".wifiwatcher"];
    
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
                // Expand the tilde in the path if present
                if ([scriptToExecute hasPrefix:@"~/"]) {
                    scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
                }
                
                [self executeScript:scriptToExecute];
            }
            continue;
        }
        
        // Check all conditions (logical AND)
        BOOL shouldExecute = YES;
        for (NSString *condition in conditions) {
            if (![self checkCondition:condition againstSSID:currentSSID isConnect:isConnect]) {
                shouldExecute = NO;
                break;
            }
        }
        
        // Execute the script if all conditions are met
        if (shouldExecute) {
            // Expand the tilde in the path if present
            if ([scriptToExecute hasPrefix:@"~/"]) {
                scriptToExecute = [scriptToExecute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:homeDir];
            }
            
            [self executeScript:scriptToExecute];
        }
    }
}

- (void)executeScript:(NSString *)scriptPath {
    colorLog(ANSI_PRIMARY, @"SCRIPT", @"Executing", [NSString stringWithFormat:@"%@", scriptPath]);
    
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
    
    // For disconnect events, pass the previous SSID
    if (!self.isConnected && self.previousSSID) {
        [env setObject:self.previousSSID forKey:@"WIFI_PREVIOUS_SSID"];
    }
    
    // Set current timestamp (UTC)
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [env setObject:[formatter stringFromDate:[NSDate date]] forKey:@"WIFI_TIMESTAMP"];
    
    // Set username
    [env setObject:NSUserName() forKey:@"WIFI_USER"];
    
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
    
    // Store previous SSID before updating
    if (wasConnected && !isConnected) {
        self.previousSSID = self.lastSSID;
    }
    
    // Update current connection state
    self.isConnected = isConnected;

    // Only log on actual SSID change
    if (![ssid isEqualToString:self.lastSSID] || connectionStateChanged) {
        BOOL isConnect = YES;
        
        // Store the new SSID
        self.lastSSID = ssid;

        if ([ssid isEqualToString:@"(none)"]) {
            colorLog(ANSI_WARNING, @"WIFI", @"Disconnected", [NSString stringWithFormat:@"Interface: %@", interfaceName]);
            isConnect = NO;
        } else {
            colorLog(ANSI_SUCCESS, @"WIFI", @"Connected", [NSString stringWithFormat:@"SSID: '%@' | RSSI: %@ dBm", ssid, rssiString]);
            isConnect = YES;
        }
        
        // Execute scripts from .wifiwatcher with connection state
        [self executeWifiWatcherScripts:ssid isConnect:isConnect];
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