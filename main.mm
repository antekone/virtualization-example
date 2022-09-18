#import <Cocoa/Cocoa.h>
#import <Virtualization/Virtualization.h>
#import <Foundation/Foundation.h>

#include <iostream>
using namespace std;

static inline NSString* getPath(const char* fn) { return [NSString stringWithFormat:@"/Volumes/SSD/VM.bundle/%s", fn]; }
//static inline NSString* getPath(const char* fn) { return [NSString stringWithFormat:@"/Volumes/MacExtension/VM.bundle/%s", fn]; }
//static inline NSString* getPath(const char* fn) { return [NSString stringWithFormat:@"/Users/antek/VM.bundle/%s", fn]; }
static inline NSURL* getAuxiliaryStorageURL() { return [[NSURL alloc] initFileURLWithPath:getPath("AuxiliaryStorage")]; }
static inline NSURL* getDiskImageURL() { return [[NSURL alloc] initFileURLWithPath:getPath("Disk.img")]; }
static inline NSURL* getHardwareModelURL() { return [[NSURL alloc] initFileURLWithPath:getPath("HardwareModel")]; }
static inline NSURL* getMachineIdentifierURL() { return [[NSURL alloc] initFileURLWithPath:getPath("MachineIdentifier")]; }

@interface _VZVirtualMachineStartOptions : NSObject
@property BOOL panicAction;
@property BOOL stopInIBootStage1;
@property BOOL stopInIBootStage2;
@property BOOL bootMacOSRecovery;
@property BOOL forceDFU;
@end

@interface _X : NSObject
- (void)_startWithOptions:(_VZVirtualMachineStartOptions*)opts completionHandler:(void (^)(NSError * _Nullable errorOrNil))handler;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
//@property (strong) VZVirtualMachineView* view;
@property (strong) NSWindow* window;
- (void)createWindow;
- (VZVirtualMachine*)createVm;
@end
@implementation AppDelegate {
    VZVirtualMachine* vm;
}
- (void)createWindow {
    NSLog(@"creating window");
    self.window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 640, 480)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered
        defer:NO];
    [self.window setTitle:@"VM Runner"];
    [self.window center];
    [self.window setIsVisible:YES];
    [self.window makeKeyAndOrderFront:nil];
    self.window.autorecalculatesKeyViewLoop = TRUE;

    NSMenu *menubar = [NSMenu new];
    NSMenuItem *menuBarItem = [NSMenuItem new];
    [menubar addItem:menuBarItem];
    [NSApp setMainMenu:menubar];
    NSMenu *appMenu = [NSMenu new];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
    action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [menuBarItem setSubmenu:appMenu];
}
- (VZVirtualMachine*)createVm {
    VZVirtualMachineConfiguration* config = [VZVirtualMachineConfiguration new];

    NSData* hardwareModelData = [[NSData alloc] initWithContentsOfURL:getHardwareModelURL()];
    NSData* machineIdentifierData = [[NSData alloc] initWithContentsOfURL:getMachineIdentifierURL()];
    VZMacAuxiliaryStorage* auxStorage = [[VZMacAuxiliaryStorage alloc] initWithContentsOfURL:getAuxiliaryStorageURL()];
    VZMacHardwareModel* hardwareModel = [[VZMacHardwareModel alloc] initWithDataRepresentation:hardwareModelData];
    VZMacMachineIdentifier* machineId = [[VZMacMachineIdentifier alloc] initWithDataRepresentation:machineIdentifierData];

    assert(hardwareModelData);
    assert(machineIdentifierData);
    assert(auxStorage);
    assert(hardwareModel);
    assert(machineId);

    VZMacPlatformConfiguration* platform = [[VZMacPlatformConfiguration alloc] init];
    platform.auxiliaryStorage = auxStorage;
    platform.hardwareModel = hardwareModel;
    platform.machineIdentifier = machineId;

    VZMacGraphicsDeviceConfiguration* gfx = [[VZMacGraphicsDeviceConfiguration alloc] init];
    gfx.displays = @[
        [[VZMacGraphicsDisplayConfiguration alloc] initWithWidthInPixels:1024 heightInPixels:768 pixelsPerInch:80]
    ];

    NSError* error;
    VZDiskImageStorageDeviceAttachment* diskAttachment = [[VZDiskImageStorageDeviceAttachment alloc] initWithURL:getDiskImageURL() readOnly:NO error:&error];
    VZVirtioBlockDeviceConfiguration* disk = [[VZVirtioBlockDeviceConfiguration alloc] initWithAttachment:diskAttachment];

    NSLog(@"Disk NSError code=%ld", error.code);

    VZNATNetworkDeviceAttachment* natAttachment = [[VZNATNetworkDeviceAttachment alloc] init];
    VZVirtioNetworkDeviceConfiguration* nic = [[VZVirtioNetworkDeviceConfiguration alloc] init];
    nic.attachment = natAttachment;

    VZUSBScreenCoordinatePointingDeviceConfiguration* mouse = [[VZUSBScreenCoordinatePointingDeviceConfiguration alloc] init];
    VZUSBKeyboardConfiguration* keyboard = [[VZUSBKeyboardConfiguration alloc] init];

    config.platform = platform;
    config.CPUCount = 2;
    config.memorySize = 4ull * 1024ull * 1024ull * 1024ull;
    config.bootLoader = [[VZMacOSBootLoader alloc] init];
    config.graphicsDevices = @[gfx];
    config.storageDevices = @[disk];
    config.networkDevices = @[nic];
    config.pointingDevices = @[mouse];
    config.keyboards = @[keyboard];

    NSError* err = nil;
    BOOL ret = [config validateWithError:&err];
    if (!ret) {
        NSLog(@"Error!");
        NSLog(@"LocalizedDescription: %@", err.localizedDescription);
        abort();
    }

    return [[VZVirtualMachine alloc] initWithConfiguration:config];
}
- (void)applicationDidFinishLaunching:(NSNotification*)notif {
    NSLog(@"App policy change...");
    BOOL succ = [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSLog(@"succ=%d", succ);
    NSLog(@"Setting up VM...");
    self->vm = [self createVm];
    NSLog(@"VM created");

    [self createWindow];
    VZVirtualMachineView* view = [[VZVirtualMachineView alloc] init];
    view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Starting VM...");
        view.capturesSystemKeys = TRUE;
        view.virtualMachine = self->vm;
        [self.window setContentView:view];

        _VZVirtualMachineStartOptions* opts = [[_VZVirtualMachineStartOptions alloc] init];
        opts.bootMacOSRecovery = FALSE;
        _X* x = (_X*) self->vm;

        [x _startWithOptions:opts completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                abort();
            }
        }];

        //  [self->vm startWithCompletionHandler:^(NSError * _Nullable error) {
        //      if (error) {
        //          NSLog(@"%@", error.localizedDescription);
        //          abort();
        //      }
        //  }];
    });
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
@end

int main(int argc, const char * argv[]) {
    AppDelegate* delegate = [[AppDelegate alloc] init];
    [NSApplication sharedApplication];
    [NSApp setDelegate:delegate];
    [NSApp activateIgnoringOtherApps:YES];
    return NSApplicationMain(argc, argv);
}
