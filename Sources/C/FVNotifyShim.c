// FVNotifyShim.c —— Darwin 通知的最小桥
//
// 为什么不用 CFNotificationCenter：这套 SDK 里 CFNotificationCenterAddObserver
// 的 name/object 参数导入成 UnsafeRawPointer，Swift 侧要手拼裸指针且回调要自己保活。
// libnotify 的 block 版本干净得多，而且它就是 Darwin 通知的正主。

#include <notify.h>
#include <dispatch/dispatch.h>
#include <stdlib.h>
#include <string.h>

void FVPostDarwin(const char *name) {
    if (name) notify_post(name);
}

void FVObserveDarwin(const char *name, void (*handler)(const char *)) {
    if (!name || !handler) return;
    // notify_register_dispatch 的 name 必须长期有效，拷一份
    char *copy = strdup(name);
    if (!copy) return;
    int token = 0;
    notify_register_dispatch(copy, &token, dispatch_get_main_queue(), ^(int t) {
        (void)t;
        handler(copy);
    });
}
