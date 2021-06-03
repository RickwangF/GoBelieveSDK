//
//  IMessage+CreatorMode.m
//  GobelieveTests
//
//  Created by Tingsong Xu on 2021/6/1.
//

#import "IMessage+CreatorMode.h"

/// 获取文本，返回永远非nil的字符串，若文本不存在则返回空字符串
/// @param text 原始文本
NSString * _Nonnull safeText(NSString * _Nullable text) {
    return text ? text:@"";
}

/// 文本最大显示长度
static NSInteger maxTextLenght = 50;

@implementation IMessage (CreatorMode)

+ (NSArray<IMessage *> *)randomTextMessagesWithCount:(NSInteger)count {
    NSMutableArray<IMessage *> *texts = [[NSMutableArray alloc] initWithCapacity:count];
    NSArray<NSString *> *contents = [self chatTexts];
    NSArray<NSNumber *> *senders = @[@(1000), @(2000), @(3000)];
    NSArray<NSNumber *> *fromIDS = @[@(1), @(2), @(3)];
    NSArray<NSNumber *> *targetIDS = @[@(808)];
    NSArray<NSNumber *> *receivers = @[@(99999999999)];
    
    for (int i = 0; i<count; i++) {
        [texts addObject:[IMessage textMessage:contents[i % contents.count]
                                        sender:senders[i % senders.count].longLongValue
                                      receiver:receivers[i % receivers.count].longLongValue
                                      targetId:[NSString stringWithFormat:@"n_staff_%@", targetIDS[i % targetIDS.count]]
                                        fromId:[NSString stringWithFormat:@"n_staff_%@", fromIDS[i % fromIDS.count]]
                                      pushTips:[NSString stringWithFormat:@"n_staff_%@|staff_staff", targetIDS[i % targetIDS.count]]
                                          uuid:[self uuidString]
                                       xtenant:0]];
    }
    return texts;
}

/// 创建文本消息对象
/// @param text 文本
/// @param sender 发送者
/// @param receiver 接收者
/// @param targetId 发送者username，如n_1000
/// @param fromId 接收者username，如n_1000
/// @param pushTips 推送相关标签
/// @param uuid 消息唯一标识符
/// @param xtenant 此字段未确认功能（可能和租户隔离有关）
+ (IMessage *)textMessage:(NSString * _Nonnull)text
                   sender:(int64_t)sender
                 receiver:(int64_t)receiver
                 targetId:(NSString * _Nonnull)targetId
                   fromId:(NSString * _Nonnull)fromId
                 pushTips:(NSString * _Nonnull)pushTips
                     uuid:(NSString * _Nonnull)uuid
                  xtenant:(NSInteger)xtenant {
    IMessage *message = [[IMessage alloc] init];
    NSString *placeStr = text;
    
    if (text.length > maxTextLenght) {
        placeStr = [NSString stringWithFormat:@"%@...", [text substringToIndex:maxTextLenght]];
    }
    
    NSDictionary *extraDic = @{
        @"version" : @3,
        @"platform" : [self currentPlatform],
        @"type" : @"text",
        @"content" : text,
        @"ios_push_tips" : pushTips
    };
    [message setSender:sender];
    [message setReceiver:receiver];
    [message configureMessageBodyWithExtras:extraDic placeString:placeStr targetId:targetId fromId:fromId msgUUID:uuid xtenant:xtenant];
    return message;
}

/// 配置消息体，部分字段已经写死且公用，固使用工厂处理
/// @param extras 需组装进入消息的主体
/// @param placeString 占位消息
/// @param targetId 接收方username
/// @param fromId 发送方username
/// @param msgUUID 消息唯一标识
/// @param xtenant 目前还不了解此字段
- (void)configureMessageBodyWithExtras:(NSDictionary *)extras
                            placeString:(NSString *)placeString
                              targetId:(NSString *)targetId
                                fromId:(NSString *)fromId
                               msgUUID:(NSString *)msgUUID
                               xtenant:(NSInteger)xtenant {
    [self setHaveRead:NO];
    [self setReadUUID:msgUUID];
    
    NSDictionary *extraDic = [[NSDictionary alloc] initWithDictionary:extras];
    NSDictionary *msg_body = @{
        @"text" : safeText(placeString),
        @"extras" : extraDic ?: @{},
    };
    
    NSDictionary *messageDic = @{
        @"version" : @3,
        @"target_type" : @"single",
        @"xtenant" : @(xtenant),
        @"target_uid" : @(self.receiver),
        @"from_uid" : @(self.sender),
        @"target_id" : safeText(targetId),
        @"from_type" : @"user",
        @"from_id" : safeText(fromId),
        @"msg_type" : @"text",
        @"msg_uuid" : msgUUID,
        @"msg_body" : msg_body
    };
    
    MessageTextContent *textContent = [[MessageTextContent alloc] initWithTextDic:messageDic];
    [self setContent:textContent];
    [self setRawContent:textContent.raw];
    [self setTimestamp:[IMessage getNowTimeTimestamp]];
}


#pragma mark - Helper
/// 获取组装进入消息体的版本信息
+ (NSString *)currentPlatform {
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"iOS/%@",appVersion];
}

///获取组装进入消息体的时间（Unix时间戳）
+ (NSInteger)getNowTimeTimestamp {
    NSDate *datenow = [NSDate date]; //现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
    return [timeSp integerValue];
}

/// 测试聊天数据
+ (NSArray<NSString *> *)chatTexts {
    return @[
        @"系统是纯C写的，效率是很高的。。。结果跑了4小时没反应。。。气死我了。。 ",
        @"后来我帮他改后，20分钟就跑完的程序。。。汗。。。 ",
        @"rickya 你考虑到数据采集时，从sybase到其他的数据库，java代码怎么写么？ ",
        @"我们没用sybase ",
        @"哦，是不是他没有释放资源，把内存搞光了 ",
        @"java我也不太懂。。。我就用的C和C＋＋。。。其它都不太会呢。 ",
        @"那到不是。。。是取数都不走索引。 ",
        @"最后我问他为什么不走索引。他说索引没什么用。。。 ",
        @"  ",
        @"金融数据量太大了 ",
        @"气得我当时直吐血。。。 ",
        @"一个select 估计要很长时间 ",
        @"嗯。几千万条数据，不走索引不是找死是干什么？ ",
        @"  ",
        @"还研究生。。。 ",
        @"他们用什么库 ",
        @"你采集放到什么库 ",
        @"informix ",
        @"哦，金融的数据是怕人 ",
        @"采集到的就在informix里，只是另一个库里 ",
        @"哦，那还好 ",
        @"假如采集到sybase库，那么就存在类型转换的问题 ",
        @"sybase我们没怎么用，主要是人行在用。 ",
        @"银联用的DB2 ",
        @"银联也是从人行出去的吧 ",
        @"枫-rickya 简单介绍一下 你是怎么处理的 他们是怎么处理的？ ",
        @"后来的 没跟上 ",
        @"嗯。以前叫什么金卡工程，就是那些人出去的。 ",
        @"也就是银行的行业协会组织 ",
        @"那很简单嘛，查询走索引，然后程序写成一个多线程，进行并发就是了。。。 ",
        @"跨行支付，以及多终端支付 ",
        @"银行的行业协组织主要是几家大行了。 ",
        @"100条20分钟？ ",
        @"。。。。 ",
        @"线程怎么控制那个线程采集前面的10万条 ，别的线程采集后面的10万条 ",
        @"8000万条数据。 ",
        @"把数据进行分组。 ",
        @"咋分组呢？  ",
        @"比如说吧，按机构来进行分组。",
        @"这样啊 ",
        @"有道理 ",
        @"每个线程处理一个段机构的数据 ",
        @"哦 ",
        @"程序写得只要灵活点，就可能自动分组。 ",
        @"那8000万条，放到别的库里面做什么，这么多条数据，不如直接数据恢复把不要的数据在删除了 ",
        @"不是放到别的库，是从8000万条数据里找到适合条件r ",
        @"哦，这样啊 ",
        @"呵呵，辛苦了 ",
        @"8000万条数据是一个交易明细嘛。 ",
        @"8000万，你多少条做一个事务提交 ",
        @"银行的同学们.怎样把信息收集到一起呢? "];
};

+ (NSString *)uuidString {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}

@end
