/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageDownloader.h>
#import <TMSDWebImage/TMSDWebImageDownloaderConfig.h>
#import <TMSDWebImage/TMSDWebImageDownloaderOperation.h>
#import <TMSDWebImage/TMSDWebImageError.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

NSNotificationName const TMSDWebImageDownloadStartNotification = @"TMSDWebImageDownloadStartNotification";
NSNotificationName const TMSDWebImageDownloadReceiveResponseNotification = @"TMSDWebImageDownloadReceiveResponseNotification";
NSNotificationName const TMSDWebImageDownloadStopNotification = @"TMSDWebImageDownloadStopNotification";
NSNotificationName const TMSDWebImageDownloadFinishNotification = @"TMSDWebImageDownloadFinishNotification";

static void * TMSDWebImageDownloaderContext = &TMSDWebImageDownloaderContext;

@interface TMSDWebImageDownloadToken ()

@property (nonatomic, strong, nullable, readwrite) NSURL *url;
@property (nonatomic, strong, nullable, readwrite) NSURLRequest *request;
@property (nonatomic, strong, nullable, readwrite) NSURLResponse *response;
@property (nonatomic, strong, nullable, readwrite) NSURLSessionTaskMetrics *metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
@property (nonatomic, weak, nullable, readwrite) id downloadOperationCancelToken;
@property (nonatomic, weak, nullable) NSOperation<TMSDWebImageDownloaderOperation> *downloadOperation;
@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;
- (nonnull instancetype)initWithDownloadOperation:(nullable NSOperation<TMSDWebImageDownloaderOperation> *)downloadOperation;

@end

@interface TMSDWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;
@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, NSOperation<TMSDWebImageDownloaderOperation> *> *URLOperations;
@property (strong, nonatomic, nullable) NSMutableDictionary<NSString *, NSString *> *HTTPHeaders;

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation TMSDWebImageDownloader {
    TMSD_LOCK_DECLARE(_HTTPHeadersLock); // A lock to keep the access to `HTTPHeaders` thread-safe
    TMSD_LOCK_DECLARE(_operationsLock); // A lock to keep the access to `URLOperations` thread-safe
}

+ (void)initialize {
    // Bind TMSDNetworkActivityIndicator if available (download it here: http://github.com/rs/TMSDNetworkActivityIndicator )
    // To use it, just add #import <TMSDWebImage/TMSDNetworkActivityIndicator.h> in addition to the TMSDWebImage import
    if (NSClassFromString(@"TMSDNetworkActivityIndicator")) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"TMSDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:TMSDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:TMSDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:TMSDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:TMSDWebImageDownloadStopNotification object:nil];
    }
}

+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init {
    return [self initWithConfig:TMSDWebImageDownloaderConfig.defaultDownloaderConfig];
}

- (instancetype)initWithConfig:(TMSDWebImageDownloaderConfig *)config {
    self = [super init];
    if (self) {
        if (!config) {
            config = TMSDWebImageDownloaderConfig.defaultDownloaderConfig;
        }
        _config = [config copy];
        [_config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxConcurrentDownloads)) options:0 context:TMSDWebImageDownloaderContext];
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = _config.maxConcurrentDownloads;
        _downloadQueue.name = @"com.hackemist.TMSDWebImageDownloader";
        _URLOperations = [NSMutableDictionary new];
        NSMutableDictionary<NSString *, NSString *> *headerDictionary = [NSMutableDictionary dictionary];
        NSString *userAgent = nil;
#if TMSD_UIKIT
        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TMSD_WATCH
        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif TMSD_MAC
        userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
        if (userAgent) {
            if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                NSMutableString *mutableUserAgent = [userAgent mutableCopy];
                if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                    userAgent = mutableUserAgent;
                }
            }
            headerDictionary[@"User-Agent"] = userAgent;
        }
        headerDictionary[@"Accept"] = @"image/*,*/*;q=0.8";
        _HTTPHeaders = headerDictionary;
        TMSD_LOCK_INIT(_HTTPHeadersLock);
        TMSD_LOCK_INIT(_operationsLock);
        NSURLSessionConfiguration *sessionConfiguration = _config.sessionConfiguration;
        if (!sessionConfiguration) {
            sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        /**
         *  Create the session for this task
         *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
         *  method calls and completion handler calls.
         */
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return self;
}

- (void)dealloc {
    [self.downloadQueue cancelAllOperations];
    [self.config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxConcurrentDownloads)) context:TMSDWebImageDownloaderContext];
    
    // Invalide the URLSession after all operations been cancelled
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)invalidateSessionAndCancel:(BOOL)cancelPendingOperations {
    if (self == [TMSDWebImageDownloader sharedDownloader]) {
        return;
    }
    if (cancelPendingOperations) {
        [self.session invalidateAndCancel];
    } else {
        [self.session finishTasksAndInvalidate];
    }
}

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field {
    if (!field) {
        return;
    }
    TMSD_LOCK(_HTTPHeadersLock);
    [self.HTTPHeaders setValue:value forKey:field];
    TMSD_UNLOCK(_HTTPHeadersLock);
}

- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field {
    if (!field) {
        return nil;
    }
    TMSD_LOCK(_HTTPHeadersLock);
    NSString *value = [self.HTTPHeaders objectForKey:field];
    TMSD_UNLOCK(_HTTPHeadersLock);
    return value;
}

- (nullable TMSDWebImageDownloadToken *)downloadImageWithURL:(NSURL *)url
                                                 completed:(TMSDWebImageDownloaderCompletedBlock)completedBlock {
    return [self downloadImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (nullable TMSDWebImageDownloadToken *)downloadImageWithURL:(NSURL *)url
                                                   options:(TMSDWebImageDownloaderOptions)options
                                                  progress:(TMSDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(TMSDWebImageDownloaderCompletedBlock)completedBlock {
    return [self downloadImageWithURL:url options:options context:nil progress:progressBlock completed:completedBlock];
}

- (nullable TMSDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(TMSDWebImageDownloaderOptions)options
                                                   context:(nullable TMSDWebImageContext *)context
                                                  progress:(nullable TMSDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable TMSDWebImageDownloaderCompletedBlock)completedBlock {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil) {
        if (completedBlock) {
            NSError *error = [NSError errorWithDomain:TMSDWebImageErrorDomain code:TMSDWebImageErrorInvalidURL userInfo:@{NSLocalizedDescriptionKey : @"Image url is nil"}];
            completedBlock(nil, nil, error, YES);
        }
        return nil;
    }
    
    TMSD_LOCK(_operationsLock);
    id downloadOperationCancelToken;
    NSOperation<TMSDWebImageDownloaderOperation> *operation = [self.URLOperations objectForKey:url];
    // There is a case that the operation may be marked as finished or cancelled, but not been removed from `self.URLOperations`.
    if (!operation || operation.isFinished || operation.isCancelled) {
        operation = [self createDownloaderOperationWithUrl:url options:options context:context];
        if (!operation) {
            TMSD_UNLOCK(_operationsLock);
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:TMSDWebImageErrorDomain code:TMSDWebImageErrorInvalidDownloadOperation userInfo:@{NSLocalizedDescriptionKey : @"Downloader operation is nil"}];
                completedBlock(nil, nil, error, YES);
            }
            return nil;
        }
        @weakify(self);
        operation.completionBlock = ^{
            @strongify(self);
            if (!self) {
                return;
            }
            TMSD_LOCK(self->_operationsLock);
            [self.URLOperations removeObjectForKey:url];
            TMSD_UNLOCK(self->_operationsLock);
        };
        self.URLOperations[url] = operation;
        // Add the handlers before submitting to operation queue, avoid the race condition that operation finished before setting handlers.
        downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];
        // Add operation to operation queue only after all configuration done according to Apple's doc.
        // `addOperation:` does not synchronously execute the `operation.completionBlock` so this will not cause deadlock.
        [self.downloadQueue addOperation:operation];
    } else {
        // When we reuse the download operation to attach more callbacks, there may be thread safe issue because the getter of callbacks may in another queue (decoding queue or delegate queue)
        // So we lock the operation here, and in `TMSDWebImageDownloaderOperation`, we use `@synchonzied (self)`, to ensure the thread safe between these two classes.
        @synchronized (operation) {
            downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];
        }
        if (!operation.isExecuting) {
            if (options & TMSDWebImageDownloaderHighPriority) {
                operation.queuePriority = NSOperationQueuePriorityHigh;
            } else if (options & TMSDWebImageDownloaderLowPriority) {
                operation.queuePriority = NSOperationQueuePriorityLow;
            } else {
                operation.queuePriority = NSOperationQueuePriorityNormal;
            }
        }
    }
    TMSD_UNLOCK(_operationsLock);
    
    TMSDWebImageDownloadToken *token = [[TMSDWebImageDownloadToken alloc] initWithDownloadOperation:operation];
    token.url = url;
    token.request = operation.request;
    token.downloadOperationCancelToken = downloadOperationCancelToken;
    
    return token;
}

- (nullable NSOperation<TMSDWebImageDownloaderOperation> *)createDownloaderOperationWithUrl:(nonnull NSURL *)url
                                                                                  options:(TMSDWebImageDownloaderOptions)options
                                                                                  context:(nullable TMSDWebImageContext *)context {
    NSTimeInterval timeoutInterval = self.config.downloadTimeout;
    if (timeoutInterval == 0.0) {
        timeoutInterval = 15.0;
    }
    
    // In order to prevent from potential duplicate caching (NSURLCache + TMSDImageCache) we disable the cache for image requests if told otherwise
    NSURLRequestCachePolicy cachePolicy = options & TMSDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData;
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    mutableRequest.HTTPShouldHandleCookies = TMSD_OPTIONS_CONTAINS(options, TMSDWebImageDownloaderHandleCookies);
    mutableRequest.HTTPShouldUsePipelining = YES;
    TMSD_LOCK(_HTTPHeadersLock);
    mutableRequest.allHTTPHeaderFields = self.HTTPHeaders;
    TMSD_UNLOCK(_HTTPHeadersLock);
    
    // Context Option
    TMSDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    
    // Request Modifier
    id<TMSDWebImageDownloaderRequestModifier> requestModifier;
    if ([context valueForKey:TMSDWebImageContextDownloadRequestModifier]) {
        requestModifier = [context valueForKey:TMSDWebImageContextDownloadRequestModifier];
    } else {
        requestModifier = self.requestModifier;
    }
    
    NSURLRequest *request;
    if (requestModifier) {
        NSURLRequest *modifiedRequest = [requestModifier modifiedRequestWithRequest:[mutableRequest copy]];
        // If modified request is nil, early return
        if (!modifiedRequest) {
            return nil;
        } else {
            request = [modifiedRequest copy];
        }
    } else {
        request = [mutableRequest copy];
    }
    // Response Modifier
    id<TMSDWebImageDownloaderResponseModifier> responseModifier;
    if ([context valueForKey:TMSDWebImageContextDownloadResponseModifier]) {
        responseModifier = [context valueForKey:TMSDWebImageContextDownloadResponseModifier];
    } else {
        responseModifier = self.responseModifier;
    }
    if (responseModifier) {
        mutableContext[TMSDWebImageContextDownloadResponseModifier] = responseModifier;
    }
    // Decryptor
    id<TMSDWebImageDownloaderDecryptor> decryptor;
    if ([context valueForKey:TMSDWebImageContextDownloadDecryptor]) {
        decryptor = [context valueForKey:TMSDWebImageContextDownloadDecryptor];
    } else {
        decryptor = self.decryptor;
    }
    if (decryptor) {
        mutableContext[TMSDWebImageContextDownloadDecryptor] = decryptor;
    }
    
    context = [mutableContext copy];
    
    // Operation Class
    Class operationClass = self.config.operationClass;
    if (operationClass && [operationClass isSubclassOfClass:[NSOperation class]] && [operationClass conformsToProtocol:@protocol(TMSDWebImageDownloaderOperation)]) {
        // Custom operation class
    } else {
        operationClass = [TMSDWebImageDownloaderOperation class];
    }
    NSOperation<TMSDWebImageDownloaderOperation> *operation = [[operationClass alloc] initWithRequest:request inSession:self.session options:options context:context];
    
    if ([operation respondsToSelector:@selector(setCredential:)]) {
        if (self.config.urlCredential) {
            operation.credential = self.config.urlCredential;
        } else if (self.config.username && self.config.password) {
            operation.credential = [NSURLCredential credentialWithUser:self.config.username password:self.config.password persistence:NSURLCredentialPersistenceForSession];
        }
    }
        
    if ([operation respondsToSelector:@selector(setMinimumProgressInterval:)]) {
        operation.minimumProgressInterval = MIN(MAX(self.config.minimumProgressInterval, 0), 1);
    }
    
    if ([operation respondsToSelector:@selector(setAcceptableStatusCodes:)]) {
        operation.acceptableStatusCodes = self.config.acceptableStatusCodes;
    }
    
    if ([operation respondsToSelector:@selector(setAcceptableContentTypes:)]) {
        operation.acceptableContentTypes = self.config.acceptableContentTypes;
    }
    
    if (options & TMSDWebImageDownloaderHighPriority) {
        operation.queuePriority = NSOperationQueuePriorityHigh;
    } else if (options & TMSDWebImageDownloaderLowPriority) {
        operation.queuePriority = NSOperationQueuePriorityLow;
    }
    
    if (self.config.executionOrder == TMSDWebImageDownloaderLIFOExecutionOrder) {
        // Emulate LIFO execution order by systematically, each previous adding operation can dependency the new operation
        // This can gurantee the new operation to be execulated firstly, even if when some operations finished, meanwhile you appending new operations
        // Just make last added operation dependents new operation can not solve this problem. See test case #test15DownloaderLIFOExecutionOrder
        for (NSOperation *pendingOperation in self.downloadQueue.operations) {
            [pendingOperation addDependency:operation];
        }
    }
    
    return operation;
}

- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}

#pragma mark - Properties

- (BOOL)isSuspended {
    return self.downloadQueue.isSuspended;
}

- (void)setSuspended:(BOOL)suspended {
    self.downloadQueue.suspended = suspended;
}

- (NSUInteger)currentDownloadCount {
    return self.downloadQueue.operationCount;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    return self.session.configuration;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == TMSDWebImageDownloaderContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxConcurrentDownloads))]) {
            self.downloadQueue.maxConcurrentOperationCount = self.config.maxConcurrentDownloads;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Helper methods

- (NSOperation<TMSDWebImageDownloaderOperation> *)operationWithTask:(NSURLSessionTask *)task {
    NSOperation<TMSDWebImageDownloaderOperation> *returnOperation = nil;
    for (NSOperation<TMSDWebImageDownloaderOperation> *operation in self.downloadQueue.operations) {
        if ([operation respondsToSelector:@selector(dataTask)]) {
            // So we lock the operation here, and in `TMSDWebImageDownloaderOperation`, we use `@synchonzied (self)`, to ensure the thread safe between these two classes.
            NSURLSessionTask *operationTask;
            @synchronized (operation) {
                operationTask = operation.dataTask;
            }
            if (operationTask.taskIdentifier == task.taskIdentifier) {
                returnOperation = operation;
                break;
            }
        }
    }
    return returnOperation;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NSURLSessionResponseAllow);
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {

    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
        [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(proposedResponse);
        }
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [dataOperation URLSession:session task:task didCompleteWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [dataOperation URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(request);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
        [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    
    // Identify the operation that runs this task and pass it the delegate method
    NSOperation<TMSDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]) {
        [dataOperation URLSession:session task:task didFinishCollectingMetrics:metrics];
    }
}

@end

@implementation TMSDWebImageDownloadToken

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TMSDWebImageDownloadReceiveResponseNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TMSDWebImageDownloadStopNotification object:nil];
}

- (instancetype)initWithDownloadOperation:(NSOperation<TMSDWebImageDownloaderOperation> *)downloadOperation {
    self = [super init];
    if (self) {
        _downloadOperation = downloadOperation;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidReceiveResponse:) name:TMSDWebImageDownloadReceiveResponseNotification object:downloadOperation];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidStop:) name:TMSDWebImageDownloadStopNotification object:downloadOperation];
    }
    return self;
}

- (void)downloadDidReceiveResponse:(NSNotification *)notification {
    NSOperation<TMSDWebImageDownloaderOperation> *downloadOperation = notification.object;
    if (downloadOperation && downloadOperation == self.downloadOperation) {
        self.response = downloadOperation.response;
    }
}

- (void)downloadDidStop:(NSNotification *)notification {
    NSOperation<TMSDWebImageDownloaderOperation> *downloadOperation = notification.object;
    if (downloadOperation && downloadOperation == self.downloadOperation) {
        if ([downloadOperation respondsToSelector:@selector(metrics)]) {
            if (@available(iOS 10.0, tvOS 10.0, macOS 10.12, watchOS 3.0, *)) {
                self.metrics = downloadOperation.metrics;
            }
        }
    }
}

- (void)cancel {
    @synchronized (self) {
        if (self.isCancelled) {
            return;
        }
        self.cancelled = YES;
        [self.downloadOperation cancel:self.downloadOperationCancelToken];
        self.downloadOperationCancelToken = nil;
    }
}

@end

@implementation TMSDWebImageDownloader (TMSDTMSDImageLoader)

- (BOOL)canRequestImageForURL:(NSURL *)url {
    return [self canRequestImageForURL:url options:0 context:nil];
}

- (BOOL)canRequestImageForURL:(NSURL *)url options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context {
    if (!url) {
        return NO;
    }
    // Always pass YES to let URLSession or custom download operation to determine
    return YES;
}

- (id<TMSDWebImageOperation>)requestImageWithURL:(NSURL *)url options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context progress:(TMSDImageLoaderProgressBlock)progressBlock completed:(TMSDImageLoaderCompletedBlock)completedBlock {
    UIImage *cachedImage = context[TMSDWebImageContextLoaderCachedImage];
    
    TMSDWebImageDownloaderOptions downloaderOptions = 0;
    if (options & TMSDWebImageLowPriority) downloaderOptions |= TMSDWebImageDownloaderLowPriority;
    if (options & TMSDWebImageProgressiveLoad) downloaderOptions |= TMSDWebImageDownloaderProgressiveLoad;
    if (options & TMSDWebImageRefreshCached) downloaderOptions |= TMSDWebImageDownloaderUseNSURLCache;
    if (options & TMSDWebImageContinueInBackground) downloaderOptions |= TMSDWebImageDownloaderContinueInBackground;
    if (options & TMSDWebImageHandleCookies) downloaderOptions |= TMSDWebImageDownloaderHandleCookies;
    if (options & TMSDWebImageAllowInvalidSSLCertificates) downloaderOptions |= TMSDWebImageDownloaderAllowInvalidSSLCertificates;
    if (options & TMSDWebImageHighPriority) downloaderOptions |= TMSDWebImageDownloaderHighPriority;
    if (options & TMSDWebImageScaleDownLargeImages) downloaderOptions |= TMSDWebImageDownloaderScaleDownLargeImages;
    if (options & TMSDWebImageAvoidDecodeImage) downloaderOptions |= TMSDWebImageDownloaderAvoidDecodeImage;
    if (options & TMSDWebImageDecodeFirstFrameOnly) downloaderOptions |= TMSDWebImageDownloaderDecodeFirstFrameOnly;
    if (options & TMSDWebImagePreloadAllFrames) downloaderOptions |= TMSDWebImageDownloaderPreloadAllFrames;
    if (options & TMSDWebImageMatchAnimatedImageClass) downloaderOptions |= TMSDWebImageDownloaderMatchAnimatedImageClass;
    
    if (cachedImage && options & TMSDWebImageRefreshCached) {
        // force progressive off if image already cached but forced refreshing
        downloaderOptions &= ~TMSDWebImageDownloaderProgressiveLoad;
        // ignore image read from NSURLCache if image if cached but force refreshing
        downloaderOptions |= TMSDWebImageDownloaderIgnoreCachedResponse;
    }
    
    return [self downloadImageWithURL:url options:downloaderOptions context:context progress:progressBlock completed:completedBlock];
}

- (BOOL)shouldBlockFailedURLWithURL:(NSURL *)url error:(NSError *)error {
    return [self shouldBlockFailedURLWithURL:url error:error options:0 context:nil];
}

- (BOOL)shouldBlockFailedURLWithURL:(NSURL *)url error:(NSError *)error options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context {
    BOOL shouldBlockFailedURL;
    // Filter the error domain and check error codes
    if ([error.domain isEqualToString:TMSDWebImageErrorDomain]) {
        shouldBlockFailedURL = (   error.code == TMSDWebImageErrorInvalidURL
                                || error.code == TMSDWebImageErrorBadImageData);
    } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
        shouldBlockFailedURL = (   error.code != NSURLErrorNotConnectedToInternet
                                && error.code != NSURLErrorCancelled
                                && error.code != NSURLErrorTimedOut
                                && error.code != NSURLErrorInternationalRoamingOff
                                && error.code != NSURLErrorDataNotAllowed
                                && error.code != NSURLErrorCannotFindHost
                                && error.code != NSURLErrorCannotConnectToHost
                                && error.code != NSURLErrorNetworkConnectionLost);
    } else {
        shouldBlockFailedURL = NO;
    }
    return shouldBlockFailedURL;
}

@end
