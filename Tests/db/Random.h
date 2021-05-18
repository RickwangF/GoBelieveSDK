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

void randomSeed(void);

NSString* randomString(void);
NSString* randomStringCount(NSUInteger count);

NSString* _Nullable randomNullString(void);
NSString* _Nullable randomNullStringCount(NSUInteger count);

NSInteger randomInteger(void);
int randomInt(void);
int64_t randomInt64(void);

BOOL randomBool(void);

#if (__cplusplus)
};
#endif

NS_ASSUME_NONNULL_END

#endif //GOBELIEVE_RANDOM_H
