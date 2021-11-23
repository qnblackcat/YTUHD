#import "Header.h"
#import <sys/sysctl.h>
#import <version.h>

extern BOOL UseVP9();

%hook YTSettings

- (BOOL)isWebMEnabled {
    return YES;
}

%end

%group Spoofing

%hook UIDevice

- (NSString *)systemVersion {
    return @"14.8";
}

%end

%hook NSProcessInfo

- (NSOperatingSystemVersion)operatingSystemVersion {
    NSOperatingSystemVersion version;
    version.majorVersion = 14;
    version.minorVersion = 8;
    version.patchVersion = 0;
    return version;
}

%end

%hook YTVersionUtils

+ (NSString *)OSBuild {
    return @(IOS_BUILD);
}

%end

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (strcmp(name, "kern.osversion") == 0) {
        if (oldp)
            strcpy((char *)oldp, IOS_BUILD);
        *oldlenp = strlen(IOS_BUILD);
    }
    return %orig(name, oldp, oldlenp, newp, newlen);
}

%end

#ifdef SIDELOADED

#import "../PSHeader/Misc.h"

typedef struct __SecTask *SecTaskRef;
extern CFTypeRef SecTaskCopyValueForEntitlement(SecTaskRef, CFStringRef, CFErrorRef *);

%group VP9ENT

%hookf(CFTypeRef, SecTaskCopyValueForEntitlement, SecTaskRef task, CFStringRef entitlement, CFErrorRef *error) {
    if (CFStringEqual(entitlement, CFSTR("com.apple.coremedia.allow-alternate-video-decoder-selection"))) {
        return kCFBooleanTrue;
    }
    return %orig;
}

%end

#endif

%ctor {
    if (UseVP9()) {
        %init;
#ifdef SIDELOADED
        %init(VP9ENT);
#endif
        if (!IS_IOS_OR_NEWER(iOS_14_0)) {
            %init(Spoofing);
        }
    }
}
