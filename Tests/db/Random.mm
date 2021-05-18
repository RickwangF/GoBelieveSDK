//
// Created by Nan Yang on 2021/5/7.
//

#include "Random.h"
#include <cstdlib>
#include <ctime>

void randomSeed() {
    std::srand(static_cast<unsigned int>(std::time(nullptr)));
};

template <typename T = int>
T randomNumber() {
    return static_cast<T>(std::rand());
}

NSString* randomString() {
    auto count = randomNumber<NSUInteger>() % 50;
    return randomStringCount(count);
}

NSString* randomStringCount(NSUInteger count) {
    auto data = new char[count];
    for (NSUInteger i = 0; i < count; ++i) {
        auto x = std::rand() % 50;
        if (x > 25) {
            data[i] = static_cast<char>('Z' - x + 25);
        } else {
            data[i] = static_cast<char>('z' - x);
        }
    }
    auto result = [[NSString alloc] initWithBytes:data length:count encoding:NSUTF8StringEncoding];
    delete[] data;
    return result;
}

NSString* _Nullable randomNullString() {
    if (randomBool()) {
        return nil;
    }
    return randomString();
}

NSString* _Nullable randomNullStringCount(NSUInteger count) {
    if (randomBool()) {
        return nil;
    }
    return randomStringCount(count);
}

NSInteger randomInteger() {
    return randomNumber<NSInteger>();
}

int randomInt() {
    return randomNumber<int>();
}

int64_t randomInt64() {
    return randomNumber<int64_t>();
}

BOOL randomBool() {
    return (randomNumber() % 2) > 0;
}