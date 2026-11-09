//
//  FVPrivate.h —— floatingViewClone 编译期桩头
//
//  作用：让 Swift 侧看得见系统私有类与它们的 selector。
//  约束：这里**只有声明**，没有实现；编译产物里不会出现这些类的副本，
//        运行时用的是系统框架里的真类（所以不会 "Class X is implemented in both"）。
//  来源：类名与 selector 全部来自本体骨架的实际调用点，
//        不是完整头文件——只够编译，不追求穷尽。
//

#ifndef FV_PRIVATE_H
#define FV_PRIVATE_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SpringBoard

@interface SpringBoard : UIApplication
- (void)applicationDidFinishLaunching:(UIApplication *)application;
@end

@interface SBApplication : UIApplication
- (void)invalidate;
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@end

@interface SBIconView : UIView
- (id)configurationForIcon:(id)icon
             configuration:(id)configuration
                   context:(id)context;
- (id)_configurationForIcon:(id)icon
              configuration:(id)configuration
                    context:(id)context;
@end

@interface SBMainWorkspace : NSObject
- (void)_addAppLayoutToFront:(id)layout;
- (void)_removeAppLayout:(id)layout forReason:(long long)reason;
@end

@interface SBLockStateAggregator : NSObject
- (id)lockStateAggregate;
@end

@interface SBFluidSwitcherGestureManager : NSObject
- (void)grabberTongueCanceledPulling:(id)tongue;
- (void)grabberTongueEndedPulling:(id)tongue;
- (void)grabberTongueBeganPulling:(id)tongue;
@end

@interface SBFluidSwitcherViewController : UIViewController
@end

#pragma mark - FrontBoard

@interface FBScene : NSObject
- (void)invalidate;
- (void)_setPresentationContext:(id)context;
- (id)settings;
- (id)uiSettings;
- (void)updateSettingsWithBlock:(id)block;
- (void)updateSettings:(id)settings withTransitionContext:(nullable id)context completion:(nullable id)completion;
@end

@interface FBSceneManager : NSObject
+ (instancetype)sharedInstance;
- (NSArray<FBScene *> *)scenes;
- (FBScene *)sceneWithIdentifier:(NSString *)identifier;
@end

@interface FBApplicationProcess : NSObject
- (void)invalidate;
@end

@interface FBSystemServiceOpenApplicationRequest : NSObject
- (void)_setPresentationContext:(id)context;
@end

#pragma mark - BackBoardServices / RunningBoard

@interface BKSHIDEventDescriptor : NSObject
+ (instancetype)descriptorWithEventType:(unsigned int)type;
@end

@interface BKSHIDEventDeliveryManager : NSObject
+ (instancetype)sharedInstance;
@end

#pragma mark - DoNotDisturb

@interface DNDState : NSObject
- (id)activeModeConfiguration;
@end

#pragma mark - BannerKit / UserNotificationsUIKit

@interface BNContentViewController : UIViewController
- (void)viewWillAppear:(BOOL)animated;
@end

@interface NCNotificationShortLookViewController : UIViewController
- (void)viewWillAppear:(BOOL)animated;
@end

#pragma mark - UIKit 私有

@interface _UIKeyboardLayerHostView : UIView
- (void)setFrame:(CGRect)frame;
@end

@interface UIKeyboardSceneDelegate : NSObject
- (void)keyboardFrameDidChange;
@end

@interface UIRootSceneWindow : UIWindow
- (void)didAddSubview:(UIView *)view;
@end

@interface UIUndoGestureInteraction : UIGestureRecognizer
- (void)_handlePan:(id)gesture;
@end

#pragma mark - BackBoardServices / RunningBoard



#pragma mark - DoNotDisturb


#pragma mark - BannerKit / UserNotificationsUIKit



#pragma mark - UIKit 私有





#pragma mark - BackBoardServices

void BKSHIDServicesCancelTouchesOnAllDisplays(void);

@interface UIMutableApplicationSceneSettings : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic) UIUserInterfaceStyle userInterfaceStyle;
@end

#pragma mark - CoreTelephony（私有）

bool CTCellularDataPlanGetIsEnabled(void);
void CTCellularDataPlanSetIsEnabled(bool enabled);

#pragma mark - Preferences

@interface PSSpecifier : NSObject
+ (instancetype)groupSpecifier;
+ (instancetype)preferenceSpecifierNamed:(NSString *)name
                                  target:(id)target
                                     set:(nullable SEL)set
                                     get:(nullable SEL)get
                                  detail:(nullable Class)detail
                                    cell:(Class)cell
                                    edit:(nullable SEL)edit;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *identifier;
- (void)setProperty:(nullable id)value forKey:(NSString *)key;
- (nullable id)propertyForKey:(NSString *)key;
- (void)setupIconImageWithPath:(NSString *)path;
- (void)setKeyboardType:(UIKeyboardType)type autoCaps:(UITextAutocapitalizationType)caps autoCorrection:(UITextAutocorrectionType)corr;
@end

@interface PSTableCell : UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier
                    specifier:(nullable PSSpecifier *)specifier;
- (void)refreshCellContentsWithSpecifier:(nullable PSSpecifier *)specifier;
@property (nonatomic, retain, nullable) PSSpecifier *specifier;
- (void)layoutSubviews;
@end

@interface PSListController : UIViewController
- (NSArray *)specifiers;
- (PSSpecifier *)specifierForID:(NSString *)identifier;
- (void)reloadSpecifiers;
- (nullable PSSpecifier *)specifierAtIndex:(NSInteger)index;
@property (nonatomic, copy, nullable) NSString *title;
@end

@interface PSViewController : UIViewController
- (PSSpecifier *)specifier;
@end

@interface PSStaticTextCell : PSTableCell
@end

@interface PSSwitchCell : PSTableCell
@end

@interface PSLinkCell : PSTableCell
@end

@interface PSButtonCell : PSTableCell
@end

@interface PSSliderCell : PSTableCell
@end

@interface PSSegmentCell : PSTableCell
@end

@interface PSGroupCell : PSTableCell
@end

@interface PSControlTableCell : PSTableCell
- (UIControl *)control;
@end

NS_ASSUME_NONNULL_END

#pragma mark - IOKit HID（私有/半公开 C API，SDK 无 Swift 模块）

typedef struct __IOHIDEvent *IOHIDEvent;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClient;
typedef uint32_t IOHIDEventField;
typedef uint32_t IOHIDEventType;

typedef void (*IOHIDEventSystemClientEventCallback)(void *target,
                                                    void *refcon,
                                                    void *sender,
                                                    IOHIDEventType type,
                                                    IOHIDEvent event,
                                                    void *info);

IOHIDEventSystemClient IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
void IOHIDEventSystemClientScheduleWithRunLoop(IOHIDEventSystemClient client,
                                               CFRunLoopRef runLoop,
                                               CFStringRef mode);
void IOHIDEventSystemClientUnscheduleWithRunLoop(IOHIDEventSystemClient client,
                                                 CFRunLoopRef runLoop,
                                                 CFStringRef mode);
void IOHIDEventSystemClientRegisterEventCallback(IOHIDEventSystemClient client,
                                                 IOHIDEventSystemClientEventCallback callback,
                                                 void *target,
                                                 void *refcon);
void IOHIDEventSystemClientUnregisterEventCallback(IOHIDEventSystemClient client,
                                                   IOHIDEventSystemClientEventCallback callback,
                                                   void *refcon);
IOHIDEventType IOHIDEventGetType(IOHIDEvent event);
CFArrayRef IOHIDEventGetChildren(IOHIDEvent event);
double IOHIDEventGetFloatValue(IOHIDEvent event, IOHIDEventField field);
long IOHIDEventGetIntegerValue(IOHIDEvent event, IOHIDEventField field);



#endif /* FV_PRIVATE_H */
