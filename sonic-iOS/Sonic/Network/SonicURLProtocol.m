//
//  SonicURLProtocol.m
//  sonic
//
//  Tencent is pleased to support the open source community by making VasSonic available.
//  Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
//  Licensed under the BSD 3-Clause License (the "License"); you may not use this file except
//  in compliance with the License. You may obtain a copy of the License at
//
//  https://opensource.org/licenses/BSD-3-Clause
//
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
//  Copyright © 2017年 Tencent. All rights reserved.
//

#if  __has_feature(objc_arc)
#error This file must be compiled without ARC. Use -fno-objc-arc flag.
#endif

#import "SonicURLProtocol.h"
#import "SonicConstants.h"
#import "SonicEngine.h"
#import "SonicUtil.h"
#import "SonicResourceLoader.h"

static NSString *const kSonicURLClientActionDataKey = @"data";
static NSString *const kSonicURLClientActionProtocolKey = @"protocol";

@implementation SonicURLProtocolWorker

+ (instancetype)shareInstance
{
    static SonicURLProtocolWorker *worker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        worker = [[SonicURLProtocolWorker alloc] init];
    });
    return worker;
}

- (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *value = [request.allHTTPHeaderFields objectForKey:SonicHeaderKeyLoadType];
    if (value.length != 0 && [value isEqualToString:SonicHeaderValueWebviewLoad]) {
        NSString * delegateId = [request.allHTTPHeaderFields objectForKey:SonicHeaderKeyDelegateId];
        if (delegateId.length != 0) {
            NSString * sessionID = sonicSessionID(request.URL.absoluteString);
            SonicSession *session = [[SonicEngine sharedEngine] sessionWithDelegateId:delegateId];
            if (session && [sessionID isEqualToString:session.sessionID]) {
                return YES;
            }
            SonicLogEvent(@"SonicURLProtocol.canInitWithRequest error:Cannot find sonic session!");
        }
    }
    
    //Sub resource intercept
    NSString * sessionID = sonicSessionID(request.mainDocumentURL.absoluteString);
    SonicSession *session = [[SonicEngine sharedEngine] sessionById:sessionID];
    if (session.resourceLoader && [session.resourceLoader canInterceptResourceWithUrl:request.URL.absoluteString]) {
        SonicLogEvent(@"SonicURLProtocol resource should intercept:%@",request.debugDescription);
        return YES;
    }
    
    return NO;
}

- (void)startLoadingWithProtocol:(NSURLProtocol *)protocol
{    
    NSThread *currentThread = [NSThread currentThread];
    
    __weak typeof(self) weakSelf = self;
    
    NSString * sessionID = sonicSessionID(protocol.request.mainDocumentURL.absoluteString);
    SonicSession *session = [[SonicEngine sharedEngine] sessionById:sessionID];
    
    if ([session.resourceLoader canInterceptResourceWithUrl:protocol.request.URL.absoluteString]) {
        
        SonicLogEvent(@"protocol resource did start loading :%@", protocol.request.debugDescription);

        SonicSession *session = [[SonicEngine sharedEngine] sessionById:sessionID];
        
        [session.resourceLoader preloadResourceWithUrl:protocol.request.URL.absoluteString withProtocolCallBack:^(NSDictionary *param) {
            NSMutableDictionary *sonicParams = [NSMutableDictionary dictionary];
            if (protocol)
            {
                sonicParams[kSonicURLClientActionProtocolKey] = protocol;
            }
            if (param)
            {
                sonicParams[kSonicURLClientActionDataKey] = param;
            }
            [weakSelf performSelector:@selector(callClientActionWithParams:) onThread:currentThread withObject:[sonicParams copy] waitUntilDone:NO];
        }];
        
    }
    else
    {
       
        NSString *sessionID = [protocol.request valueForHTTPHeaderField:SonicHeaderKeySessionID];

        [[SonicEngine sharedEngine] registerURLProtocolCallBackWithSessionID:sessionID completion:^(NSDictionary *param) {
            NSMutableDictionary *sonicParams = [NSMutableDictionary dictionary];
            if (protocol)
            {
                sonicParams[kSonicURLClientActionProtocolKey] = protocol;
            }
            if (param)
            {
                sonicParams[kSonicURLClientActionDataKey] = param;
            }
            [weakSelf performSelector:@selector(callClientActionWithParams:) onThread:currentThread withObject:[sonicParams copy] waitUntilDone:NO];

        }];
        
    }
}

#pragma mark - Client Action
- (void)callClientActionWithParams:(NSDictionary *)sonicParams
{
    NSDictionary *params = sonicParams[kSonicURLClientActionDataKey];
    NSURLProtocol *protocol = sonicParams[kSonicURLClientActionProtocolKey];
    if (!protocol)
    {
        return;
    }
    SonicURLProtocolAction action = [params[kSonicProtocolAction]integerValue];
    switch (action) {
        case SonicURLProtocolActionRecvResponse:
        {
            NSHTTPURLResponse *resp = params[kSonicProtocolData];
            [protocol.client URLProtocol:protocol didReceiveResponse:resp cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
            break;
        case SonicURLProtocolActionLoadData:
        {
            NSData *recvData = params[kSonicProtocolData];
            if (recvData.length > 0) {
                [protocol.client URLProtocol:protocol didLoadData:recvData];
                SonicLogEvent(@"protocol did load data length:%ld",recvData.length);
            }
        }
            break;
        case SonicURLProtocolActionDidSuccess:
        {
            [protocol.client URLProtocolDidFinishLoading:protocol];
            SonicLogEvent(@"protocol did finish loading request:%@",protocol.request.debugDescription);
        }
            break;
        case SonicURLProtocolActionDidFaild:
        {
            NSError *err = params[kSonicProtocolData];
            [protocol.client URLProtocol:protocol didFailWithError:err];
        }
            break;
    }
}

@end
