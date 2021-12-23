//
//  EPeerMessageDB.h
//  gobelieve
//
//  Created by houxh on 2018/1/17.
//

#import "IMessageDB.h"
#import "SQLPeerMessageDB.h"

#import <Foundation/Foundation.h>

@interface EPeerMessageDB : SQLPeerMessageDB <IMessageDB>
+ (EPeerMessageDB *)instance;

@end
