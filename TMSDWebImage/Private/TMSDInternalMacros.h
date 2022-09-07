/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <os/lock.h>
#import <libkern/OSAtomic.h>
#import <TMSDWebImage/TMSDmetamacros.h>

#define TMSD_USE_OS_UNFAIR_LOCK TARGET_OS_MACCATALYST ||\
    (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0) ||\
    (__MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_12) ||\
    (__TV_OS_VERSION_MIN_REQUIRED >= __TVOS_10_0) ||\
    (__WATCH_OS_VERSION_MIN_REQUIRED >= __WATCHOS_3_0)

#ifndef TMSD_LOCK_DECLARE
#if TMSD_USE_OS_UNFAIR_LOCK
#define TMSD_LOCK_DECLARE(lock) os_unfair_lock lock
#else
#define TMSD_LOCK_DECLARE(lock) os_unfair_lock lock API_AVAILABLE(ios(10.0), tvos(10), watchos(3), macos(10.12)); \
OSSpinLock lock##_deprecated;
#endif
#endif

#ifndef TMSD_LOCK_DECLARE_STATIC
#if TMSD_USE_OS_UNFAIR_LOCK
#define TMSD_LOCK_DECLARE_STATIC(lock) static os_unfair_lock lock
#else
#define TMSD_LOCK_DECLARE_STATIC(lock) static os_unfair_lock lock API_AVAILABLE(ios(10.0), tvos(10), watchos(3), macos(10.12)); \
static OSSpinLock lock##_deprecated;
#endif
#endif

#ifndef TMSD_LOCK_INIT
#if TMSD_USE_OS_UNFAIR_LOCK
#define TMSD_LOCK_INIT(lock) lock = OS_UNFAIR_LOCK_INIT
#else
#define TMSD_LOCK_INIT(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) lock = OS_UNFAIR_LOCK_INIT; \
else lock##_deprecated = OS_SPINLOCK_INIT;
#endif
#endif

#ifndef TMSD_LOCK
#if TMSD_USE_OS_UNFAIR_LOCK
#define TMSD_LOCK(lock) os_unfair_lock_lock(&lock)
#else
#define TMSD_LOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_lock(&lock); \
else OSSpinLockLock(&lock##_deprecated);
#endif
#endif

#ifndef TMSD_UNLOCK
#if TMSD_USE_OS_UNFAIR_LOCK
#define TMSD_UNLOCK(lock) os_unfair_lock_unlock(&lock)
#else
#define TMSD_UNLOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_unlock(&lock); \
else OSSpinLockUnlock(&lock##_deprecated);
#endif
#endif

#ifndef TMSD_OPTIONS_CONTAINS
#define TMSD_OPTIONS_CONTAINS(options, value) (((options) & (value)) == (value))
#endif

#ifndef TMSD_CSTRING
#define TMSD_CSTRING(str) #str
#endif

#ifndef TMSD_NSSTRING
#define TMSD_NSSTRING(str) @(TMSD_CSTRING(str))
#endif

#ifndef TMSD_SEL_SPI
#define TMSD_SEL_SPI(name) NSSelectorFromString([NSString stringWithFormat:@"_%@", TMSD_NSSTRING(name)])
#endif

#ifndef weakify
#define weakify(...) \
tmsd_keywordify \
metamacro_foreach_cxt(tmsd_weakify_,, __weak, __VA_ARGS__)
#endif

#ifndef strongify
#define strongify(...) \
tmsd_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(tmsd_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")
#endif

#define tmsd_weakify_(INDEX, CONTEXT, VAR) \
CONTEXT __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

#define tmsd_strongify_(INDEX, VAR) \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);

#if DEBUG
#define tmsd_keywordify autoreleasepool {}
#else
#define tmsd_keywordify try {} @catch (...) {}
#endif

#ifndef onExit
#define onExit \
tmsd_keywordify \
__strong tmsd_cleanupBlock_t metamacro_concat(tmsd_exitBlock_, __LINE__) __attribute__((cleanup(tmsd_executeCleanupBlock), unused)) = ^
#endif

typedef void (^tmsd_cleanupBlock_t)(void);

#if defined(__cplusplus)
extern "C" {
#endif
    void tmsd_executeCleanupBlock (__strong tmsd_cleanupBlock_t *block);
#if defined(__cplusplus)
}
#endif
