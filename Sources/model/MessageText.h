//
//  MessageText.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageText : MessageContent
-(id)initWithTextDic:(NSDictionary *)textDic;
- (id)initWithText:(NSString*)text;
- (id)initWithText:(NSString*)text at:(NSArray*)at atNames:(NSArray*)atNames;

@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSArray *at;
@property(nonatomic, readonly) NSArray *atNames;

//@property (nonatomic, assign) NSInteger version;
//@property (nonatomic, copy) NSString *target_type;
//@property (nonatomic, copy) NSString *target_id;
//@property (nonatomic, copy) NSString *from_type;
//@property (nonatomic, copy) NSString *from_id;
//@property (nonatomic, copy) NSString *msg_type;
//@property (nonatomic, strong) NSDictionary *textDic;

@end


typedef MessageText MessageTextContent;
