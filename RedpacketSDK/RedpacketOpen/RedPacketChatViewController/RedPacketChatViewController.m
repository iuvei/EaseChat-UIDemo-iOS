//
//  ChatWithRedPacketViewController.m
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/2/23.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RedPacketChatViewController.h"
#import "EaseRedBagCell.h"
#import "RedpacketTakenMessageTipCell.h"
#import "RedpacketViewControl.h"
#import "RPRedpacketModel.h"
#import "RedPacketUserConfig.h"
#import "RPRedpacketBridge.h"
#import "ChatDemoHelper.h"
#import "UserProfileManager.h"
//#import "UIImageView+WebCache.h"
#import "RPRedpacketUnionHandle.h"

/** 红包聊天窗口 */
@interface RedPacketChatViewController () < EaseMessageCellDelegate,
                                            EaseMessageViewControllerDataSource
                                            >

@end

@implementation RedPacketChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    /** 设置用户头像大小 */
    [[EaseRedBagCell appearance] setAvatarSize:40.f];
    /** 设置头像圆角 */
    [[EaseRedBagCell appearance] setAvatarCornerRadius:20.f];
    
    if ([self.chatToolbar isKindOfClass:[EaseChatToolbar class]]) {
        /** 红包按钮 */
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket"]
                                 highlightedImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket_high"]
                                            title:@"红包"];
    }

    
    [RedPacketUserConfig sharedConfig].chatVC = self;
    
}

/** 根据userID获得用户昵称,和头像地址 */
- (RPUserInfo *)profileEntityWith:(NSString *)userId
{
    RPUserInfo *userInfo = [RPUserInfo new];

    UserProfileEntity *profile = [[UserProfileManager sharedInstance] getUserProfileByUsername:userId];
    if (profile) {
        if (profile.nickname && profile.nickname.length > 0) {
            userInfo.userName = profile.nickname;
        } else {
            userInfo.userName = userId;
        }
    } else {
        userInfo.userName = userId;
    }
    userInfo.avatar = profile.imageUrl;
    userInfo.userID = userId;
    
    return userInfo;
}

/** 长时间按在某条Cell上的动作 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController canLongPressRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    if ([object conformsToProtocol:NSProtocolFromString(@"IMessageModel")]) {
        id <IMessageModel> messageModel = object;
        /** 如果是红包，则只显示删除按钮 */
        if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaket) {
            EaseMessageCell *cell = (EaseMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell becomeFirstResponder];
            self.menuIndexPath = indexPath;
            [self showMenuViewController:cell.bubbleView andIndexPath:indexPath messageType:EMMessageBodyTypeCmd];
            return NO;
        }else if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaketTaken) {
            return NO;
        }
    }
    return [super messageViewController:viewController canLongPressRowAtIndexPath:indexPath];
}

/** 自定义红包Cell*/
- (UITableViewCell *)messageViewController:(UITableView *)tableView
                       cellForMessageModel:(id<IMessageModel>)messageModel
{
    if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaket) {
        /** 红包的卡片样式*/
        EaseRedBagCell *cell = [tableView dequeueReusableCellWithIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]];
        if (!cell) {
            cell = [[EaseRedBagCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]
                                                   model:messageModel];
            cell.delegate = self;
            }
            cell.model = messageModel;
            return cell;
        }
    if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaketTaken) {
        /** XX人领取了你的红包的卡片样式*/
        RedpacketTakenMessageTipCell *cell =  [[RedpacketTakenMessageTipCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [cell configWithText:messageModel.text];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    return nil;
}

- (CGFloat)messageViewController:(EaseMessageViewController *)viewController
           heightForMessageModel:(id<IMessageModel>)messageModel
                   withCellWidth:(CGFloat)cellWidth
{
    if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaket)    {
        return [EaseRedBagCell cellHeightWithModel:messageModel];
    }else if ([RedPacketUserConfig messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaketTaken) {
        return [RedpacketTakenMessageTipCell heightForRedpacketMessageTipCell];
    }
    return 0;
}

/** 未读消息回执 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController shouldSendHasReadAckForMessage:(EMMessage *)message read:(BOOL)read
{
    if ([RedPacketUserConfig messageCellTypeWithDict:message.ext] != MessageCellTypeNoRedpacket) {
        return YES;
    }
    return [super shouldSendHasReadAckForMessage:message read:read];
}

- (void)messageViewController:(EaseMessageViewController *)viewController didSelectMoreView:(EaseChatBarMoreView *)moreView AtIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    RPRedpacketControllerType  redpacketVCType;
    RPUserInfo *userInfo = [RPUserInfo new];
    userInfo = [self profileEntityWith:self.conversation.conversationId];
    NSArray *groupArray = [EMGroup groupWithId:self.conversation.conversationId].occupants;
    if (self.conversation.type == EMConversationTypeChat) {
            /** 小额随机红包*/
        redpacketVCType = RPRedpacketControllerTypeRand;
    }else {
            /** 群红包*/
        redpacketVCType = RPRedpacketControllerTypeGroup;
    }
    
    /** 发红包方法*/
    [RedpacketViewControl presentRedpacketViewController:redpacketVCType
                                         fromeController:self
                                        groupMemberCount:groupArray.count
                                   withRedpacketReceiver:userInfo
                                         andSuccessBlock:^(RPRedpacketModel *model) {
        
        [weakSelf sendRedPacketMessage:model];
        
    } withFetchGroupMemberListBlock:^(RedpacketMemberListFetchBlock completionHandle) {
        /** 定向红包群成员列表页面，获取群成员列表 */
        EMGroup *group = [[[EMClient sharedClient] groupManager] getGroupSpecificationFromServerWithId:self.conversation.conversationId
                                                                                                 error:nil];
        NSMutableArray *mArray = [[NSMutableArray alloc] init];
        for (NSString *username in group.occupants) {
            /** 创建群成员用户 */
            RPUserInfo *userInfo = [self profileEntityWith:username];
            [mArray addObject:userInfo];
        }
        
        completionHandle(mArray);
        
    } andGenerateRedpacketIDBlock:nil];

}

/** 发送红包消息*/
- (void)sendRedPacketMessage:(RPRedpacketModel *)model
{
    NSMutableDictionary *mDic = [NSMutableDictionary new];
    [mDic setDictionary:[RPRedpacketUnionHandle dictWithRedpacketModel:model isACKMessage:NO]];
    [mDic setObject:@(YES) forKey:@"is_money_msg"];//红包消息标识
    NSString *messageText = [NSString stringWithFormat:@"[%@]%@", @"红包", model.greeting];
    [self sendTextMessage:messageText withExt:mDic];
}

/** 发送红包被抢的消息*/
- (void)sendRedpacketHasBeenTaked:(RPRedpacketModel *)messageModel
{
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *senderId = messageModel.sender.userID;
    NSString *conversationId = self.conversation.conversationId;
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setDictionary:[RPRedpacketUnionHandle dictWithRedpacketModel:messageModel isACKMessage:YES]];
    [dic setValue:@(YES) forKey:@"is_open_money_msg"];//红包被抢标识
    /** 忽略推送 */
    [dic setValue:@(YES) forKey:@"em_ignore_notification"];
    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", messageModel.sender.userName];
    if (self.conversation.type == EMConversationTypeChat) {
        
        [self sendTextMessage:text withExt:dic];
        
    }else{
        
        if ([senderId isEqualToString:currentUser]) {
            text = @"你领取了自己的红包";
        }else {
            /** 如果不是自己发的红包，则发送抢红包消息给对方 */
            [[EMClient sharedClient].chatManager sendMessage:[self createCmdMessageWithModel:messageModel] progress:nil completion:nil];
        }
        EMTextMessageBody *textMessageBody = [[EMTextMessageBody alloc] initWithText:text];
        EMMessage *textMessage = [[EMMessage alloc] initWithConversationID:conversationId from:currentUser to:conversationId body:textMessageBody ext:dic];
        textMessage.chatType = (EMChatType)self.conversation.type;
        textMessage.isRead = YES;
        /** 刷新当前聊天界面 */
        [self addMessageToDataSource:textMessage progress:nil];
        /** 存入当前会话并存入数据库 */
        [self.conversation insertMessage:textMessage error:nil];
    }
}

- (EMMessage *)createCmdMessageWithModel:(RPRedpacketModel *)model
{
    NSMutableDictionary *dict ;//= [model.redpacketMessageModelToDic mutableCopy];
    
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *toUser = model.sender.userID;
    EMCmdMessageBody *cmdChat = [[EMCmdMessageBody alloc] initWithAction:@"RedpacketKeyRedapcketCmd"];
    EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId from:currentUser to:toUser body:cmdChat ext:dict];
    message.chatType = EMChatTypeChat;
    
    return message;
}

/** 抢红包事件*/
- (void)messageCellSelected:(id<IMessageModel>)model
{
    __weak typeof(self) weakSelf = self;
    if ([RedPacketUserConfig messageCellTypeWithDict:model.message.ext] == MessageCellTypeRedpaket) {
        [self.view endEditing:YES];
        [RedpacketViewControl redpacketTouchedWithMessageModel:[self toRedpacketMessageModel:model]
                                            fromViewController:self
                                            redpacketGrabBlock:^(RPRedpacketModel *messageModel) {
                                                /** 抢到红包后，发送红包被抢的消息*/
                                                if (messageModel.redpacketType != RPRedpacketTypeAmount) {
                                                    [weakSelf sendRedpacketHasBeenTaked:messageModel];
                                                }
                                                
                                            } advertisementAction:^(NSDictionary *args) {
                                                /** 营销红包事件处理*/
                                                NSInteger actionType = [args[@"actionType"] integerValue];
                                                switch (actionType) {
                                                    case 0:
                                                        /** 用户点击了领取红包按钮*/
                                                        break;
                                                        
                                                    case 1: {
                                                        /** 用户点击了去看看按钮，进入到商户定义的网页 */
                                                        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
                                                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:args[@"LandingPage"]]];
                                                        [webView loadRequest:request];
                                                        
                                                        UIViewController *webVc = [[UIViewController alloc] init];
                                                        [webVc.view addSubview:webView];
                                                        [(UINavigationController *)self.presentedViewController pushViewController:webVc animated:YES];
                                                        
                                                    }
                                                        break;
                                                        
                                                    case 2: {
                                                        /** 点击了分享按钮，开发者可以根据需求自定义，动作。*/
                                                        [[[UIAlertView alloc]initWithTitle:nil
                                                                                  message:@"点击「分享」按钮，红包SDK将该红包素材内配置的分享链接传递给商户APP，由商户APP自行定义分享渠道完成分享动作。"
                                                                                 delegate:nil
                                                                        cancelButtonTitle:@"我知道了"
                                                                        otherButtonTitles:nil] show];
                                                    }
                                                        break;
                                                    default:
                                                        break;
                                                }
                                                
        }];
    } else {
        [super messageCellSelected:model];
    }

}

- (RPRedpacketModel *)toRedpacketMessageModel:(id <IMessageModel>)model
{
    NSDictionary *dict = model.message.ext;
    RPRedpacketModel *messageModel = [RPRedpacketUnionHandle modelWithChannelRedpacketDic1:dict andSender:[self profileEntityWith:model.message.from]];
    return messageModel;
}

@end