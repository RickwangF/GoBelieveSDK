# Gobelieve

## 头文件自动生成

```shell
find Sources -name "*.h" ! -name "Gobelieve.h" | sort -f | xargs basename | \
  xargs printf "#import <Gobelieve/%s>\n" > Sources/Gobelieve.h
```
