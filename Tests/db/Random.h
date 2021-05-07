//
// Created by Nan Yang on 2021/5/7.
//

#ifndef GOBELIEVE_RANDOM_H
#define GOBELIEVE_RANDOM_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if (__cplusplus)
extern "C" {
#endif

void randomSeed();

NSString* randomString();
NSString* randomStringCount(NSUInteger count);

NSString* _Nullable randomNullString();
NSString* _Nullable randomNullStringCount(NSUInteger count);

NSInteger randomInteger();
int randomInt();
int64_t randomInt64();

BOOL randomBool();

#if (__cplusplus)
};
#endif

NS_ASSUME_NONNULL_END

#endif //GOBELIEVE_RANDOM_H
