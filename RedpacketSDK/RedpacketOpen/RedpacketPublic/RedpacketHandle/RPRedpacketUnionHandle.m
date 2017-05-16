//
//  RPRedpacketUnionHandle.m
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 2017/5/9.
//  Copyright © 2017年 Mr.Yang. All rights reserved.
//

#import "RPRedpacketUnionHandle.h"
#import "RPRedpacketConstValues.h"
#import "RPRedpacketConstValues_v1.h"

#define IGNORE_PUSH_MESSAGE  @"em_ignore_notification"

@implementation RPRedpacketUnionHandle

//  生成通道中传输的Dict （兼容旧版本）
+ (NSDictionary *)dictWithRedpacketModel1:(RPRedpacketModel *)model
                            isACKMessage:(BOOL)isAckMessage
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:model.redpacketID forKey:RedpacketKeyRedpacketID1];
    
    //  发送者ID
    [dic setValue:model.sender.userID forKey:RedpacketKeyRedpacketSenderId1];
    //  发送者昵称
    [dic setValue:model.sender.userName forKey:RedpacketKeyRedpacketSenderNickname1];
    
    //  接收者ID
    [dic setValue:model.sender.userID forKey:RedpacketKeyRedpacketReceiverId1];
    //  接收者昵称
    [dic setValue:model.sender.userName forKey:RedpacketKeyRedpacketReceiverNickname1];
    
    //  除了单聊红包其它红包都是有值的
    [dic setValue:model.redpacketTypeStr forKey:RedpacketKeyRedapcketType1];
    [dic setValue:model.greeting forKey:RedpacketKeyRedpacketGreeting1];
    
    //  红包回执消息
    if (isAckMessage) {
        
        //  红包被抢消息
        [dic setValue:@(YES) forKey:RedpacketKeyRedpacketTakenMessageSign1];
        [dic setValue:model.groupID forKey:RedpacketKeyRedpacketCmdToGroup1];
        
    }else {
        
        //  红包消息
        [dic setValue:@(YES) forKey:RedpacketKeyRedpacketSign1];
        
    }
    
    //  兼容新版
    return [self newDictWithRedpacketModel:model
                              isAckMessage:isAckMessage
                                 andMutDic:dic];
}

//  生成通道中传输的Dict （新版本）
+ (NSDictionary *)dictWithRedpacketModel:(RPRedpacketModel *)model
                            isACKMessage:(BOOL)isAckMessage
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    return [self newDictWithRedpacketModel:model
                              isAckMessage:isAckMessage
                                 andMutDic:dic];
}

+ (NSDictionary *)newDictWithRedpacketModel:(RPRedpacketModel *)model
                               isAckMessage:(BOOL)isAckMessage
                                  andMutDic:(NSMutableDictionary *)dic
{
    if (isAckMessage) {
        
        //  红包被抢消息
        [dic setValue:@(YES) forKey:RedpacketKeyRedpacketTakenMessageSign];
        //  群组ID（环信IM CMD消息接收方需要根据这个入库）
        [dic setValue:model.groupID forKey:RedpacketKeyRedpacketCmdToGroup];
        //  发送者ID
        [dic setValue:model.sender.userID forKey:RedpacketKeyRedpacketSenderId];
        //  发送者昵称
        [dic setValue:model.sender.userName forKey:RedpacketKeyRedpacketSenderNickname];
        //  接收者ID
        [dic setValue:model.receiver.userID forKey:RedpacketKeyRedpacketReceiverId];
        //  接收者昵称
        [dic setValue:model.receiver.userName forKey:RedpacketKeyRedpacketReceiverNickname];
        // 忽略推送
        [dic setValue:@(YES) forKey:IGNORE_PUSH_MESSAGE];
        
    }else {
        
        //  红包ID
        [dic setValue:model.redpacketID forKey:RedpacketKeyRedpacketID];
        //  红包消息
        [dic setValue:@(YES) forKey:RedpacketKeyRedpacketSign];
        //  除了单聊红包其它红包都是有值的
        [dic setValue:model.redpacketTypeStr forKey:RedpacketKeyRedapcketType];
        //  祝福语
        [dic setValue:model.greeting forKey:RedpacketKeyRedpacketGreeting];
        
    }
    
    return dic;

}


//  IM通道中传入的Dict （旧版新版都支持）
+ (RPRedpacketModel *)modelWithChannelRedpacketDic1:(NSDictionary *)redpacketDic
                                          andSender:(RPUserInfo *)sender
{
    NSString *redpacketID = [redpacketDic objectForKey:RedpacketKeyRedpacketID1];
    NSString *redpacketType = [redpacketDic objectForKey:RedpacketKeyRedapcketType1];
    
    //  如果旧版本的Key值不存在，则用新版本
    if (redpacketID.length == 0) {
        
        //  使用新版本
        return [self modelWithChannelRedpacketDic:redpacketDic
                                        andSender:sender];
        
    }
    
    RPRedpacketModel *model = [RPRedpacketModel modelWithRedpacketID:redpacketID
                                                       redpacketType:redpacketType
                                                  andRedpacketSender:sender];
    
    return model;
}

//  IM通道中传入的Dict (新版)
+ (RPRedpacketModel *)modelWithChannelRedpacketDic:(NSDictionary *)redpacketDic
                                         andSender:(RPUserInfo *)sender
{
    NSString *redpacketID = [redpacketDic objectForKey:RedpacketKeyRedpacketID];
    NSAssert(redpacketID.length, @"红包ID为空，经检查字典中是否存在红包ID");
    
    if (redpacketID.length) {
        return nil;
    }
    
    NSString *redpacketType = [redpacketDic objectForKey:RedpacketKeyRedapcketType];

    RPRedpacketModel *model = [RPRedpacketModel modelWithRedpacketID:redpacketID
                                                       redpacketType:redpacketType
                                                  andRedpacketSender:sender];
    
    return model;
}

@end