/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDWebImageDownloaderDecryptor.h>

@interface TMSDWebImageDownloaderDecryptor ()

@property (nonatomic, copy, nonnull) TMSDWebImageDownloaderDecryptorBlock block;

@end

@implementation TMSDWebImageDownloaderDecryptor

- (instancetype)initWithBlock:(TMSDWebImageDownloaderDecryptorBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)decryptorWithBlock:(TMSDWebImageDownloaderDecryptorBlock)block {
    TMSDWebImageDownloaderDecryptor *decryptor = [[TMSDWebImageDownloaderDecryptor alloc] initWithBlock:block];
    return decryptor;
}

- (nullable NSData *)decryptedDataWithData:(nonnull NSData *)data response:(nullable NSURLResponse *)response {
    if (!self.block) {
        return nil;
    }
    return self.block(data, response);
}

@end

@implementation TMSDWebImageDownloaderDecryptor (TMSDConveniences)

+ (TMSDWebImageDownloaderDecryptor *)base64Decryptor {
    static TMSDWebImageDownloaderDecryptor *decryptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        decryptor = [TMSDWebImageDownloaderDecryptor decryptorWithBlock:^NSData * _Nullable(NSData * _Nonnull data, NSURLResponse * _Nullable response) {
            NSData *modifiedData = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
            return modifiedData;
        }];
    });
    return decryptor;
}

@end
