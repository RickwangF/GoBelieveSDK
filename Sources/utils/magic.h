//
// Created by Nan Yang on 2021/5/7.
//

#ifndef GOBELIEVE_MAGIC_H
#define GOBELIEVE_MAGIC_H

#define _str(x) #x
#define _ns_str(x) @#x
#define _join(a, b) a##b
#define _join3(a, b, c) a##b##c
#define _comma(...) #__VA_ARGS__

#define str(x) _str(x)
#define ns_str(x) _ns_str(x)
#define join(a, b) _join(a, b)
#define join3(a, b, c) _join3(a, b, c)
#define comma(...) _comma(__VA_ARGS__)

#endif //GOBELIEVE_MAGIC_H
