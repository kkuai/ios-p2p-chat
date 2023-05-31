#import "ChatViewController.h"
#import "P2PEngineContext.h"
#import "Message.h"
#import "MessageCell.h"
#import "MessageFrame.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#include <sys/time.h>

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"begin ChatViewController viewDidLoad");
    clientChannel = [[KKP2PChannel alloc] init];
    acceptChannelArray = [NSMutableArray array];
    
    self.chatTableView.dataSource = self;
    self.chatTableView.delegate = self;
    self.chatTableView.backgroundColor = BACKGROUD_COLOR;
    self.chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.chatTableView setAllowsSelection:NO];
    
    self.uploadSlider.TintColor = [UIColor redColor];
    self.uploadSlider.trackTintColor = [UIColor grayColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.chatTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    self.chatTextField.leftViewMode = UITextFieldViewModeAlways;
    self.chatTextField.delegate = self;
    
    // init kkp2p engine
    P2PEngineContext * ctx = [P2PEngineContext getInstance ];
    NSString* loginName = ctx->loginName;
    if([loginName isEqualToString:@"kkuai-ipc-00002"]){
        friendName = @"kkuai-ipc-00001";
        [_nameButton setTitle:friendName forState:UIControlStateNormal];
    } else {
        friendName = @"kkuai-ipc-00002";
        [_nameButton setTitle:friendName forState:UIControlStateNormal];
    }
    _nameButton.enabled = FALSE;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:@"notifyEvent" object:nil];
    
    // start thread to accept incoming connect
    acceptThread = [[NSThread alloc] initWithTarget:self selector:@selector(loopAcceptChannel) object:nil];
    [acceptThread start];
    
    //UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 40)];
    //[self.view  addSubview:backButton];
    //[backButton setTitle:@"back" forState:UIControlStateNormal];
    //backButton.backgroundColor = UIColor.redColor;
    //[backButton setTitleColor:UIColor.yellowColor forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backBtnPress) forControlEvents: UIControlEventTouchUpInside];
}

- (IBAction)backBtnPress {
    [acceptThread cancel];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onConnectButton:(id)sender {
    P2PEngineContext * ctx = [P2PEngineContext getInstance];
    kkp2p_connect_ctx_t connectCtx;
    memset(&connectCtx, 0, sizeof(kkp2p_connect_ctx_t));
    
    // set peer id
    const char *cString = [friendName UTF8String];
    strncpy(connectCtx.peer_id, cString, sizeof(connectCtx.peer_id)-1);
    
    // set conn mode
    NSArray *array = [ctx->connMode componentsSeparatedByString:@"|"];
    NSString *strMode = [array objectAtIndex:0];
    if ([strMode isEqualToString:@"auto"]) {
        connectCtx.connect_mode = 0;
    } else if ([strMode isEqualToString:@"p2p"]) {
        connectCtx.connect_mode = 1;
    } else if ([strMode isEqualToString:@"relay"]) {
        connectCtx.connect_mode = 2;
    } else if ([strMode isEqualToString:@"lanSearch"]) {
        connectCtx.connect_mode = 1; //lanSearch is p2p mode
    }
    
    // set encrypt data or not
    connectCtx.encrypt_data = 0;
    
    // create alike tcp channel
    connectCtx.channel_type = KKP2P_TCP_CHANNEL;
    
    // set connect timeout:ms
    connectCtx.timeout = 5000;
    
    // synchronous connect, not use asynchronous
    connectCtx.func = NULL;
    connectCtx.func_param = NULL;
    
    kkp2p_channel_t channel;
    int result = 0;
    if ([strMode isEqualToString:@"lanSearch"]) {
        result =  kkp2p_lan_search(ctx->p2pEngine, &connectCtx, &channel);
    } else {
        result =  kkp2p_connect(ctx->p2pEngine, &connectCtx, &channel);
    }
    
    if (result < 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"error" message: @"connect failure" preferredStyle: UIAlertControllerStyleAlert];
        [self presentViewController: alert animated: YES completion: nil];
        [self performSelector:@selector(dismiss:) withObject:alert afterDelay:0.5];
        return;
    }
    
    // notify success
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"connect success" message: @"" preferredStyle: UIAlertControllerStyleAlert];
    [self presentViewController: alert animated: YES completion: nil];
    [self performSelector:@selector(dismiss:) withObject:alert afterDelay:0.5];
    
    clientChannel->peer_id = [NSString stringWithUTF8String:channel.peer_id];
    clientChannel->channel_type = channel.channel_type;
    clientChannel->transmit_mode = channel.transmit_mode;
    clientChannel->encrypt_data = channel.encrypt_data;
    clientChannel->channel_id = channel.channel_id;
    clientChannel->is_ipv6_p2p = channel.is_ipv6_p2p;
    clientChannel->connect_desc = channel.connect_desc;
    clientChannel->fd = channel.fd;
    
    if (clientChannel->transmit_mode == 1) {
        if (clientChannel->is_ipv6_p2p==1) {
            [_modeButton setTitle:@"p2p(ipv6)" forState:UIControlStateNormal];
        } else {
            [_modeButton setTitle:@"p2p(ipv4)" forState:UIControlStateNormal];
        }
    } else {
        [_modeButton setTitle:@"relay" forState:UIControlStateNormal];
    }
    _modeButton.enabled = FALSE;
    
    // start thread to read message from socket
    [self performSelectorInBackground:@selector(loopReadChannel:) withObject:clientChannel];
}

- (void)dismiss:(UIAlertController *)alert {
    [alert dismissViewControllerAnimated: YES completion: nil];
}

- (void)loopAcceptChannel {
    P2PEngineContext * ctx = [P2PEngineContext getInstance ];
    kkp2p_engine_t* p2pEngine = ctx->p2pEngine;
    int listenFd = kkp2p_listen_fd(ctx->p2pEngine);
    kkp2p_channel_t acceptChannel;
    while(TRUE) {
        int result = kkp2p_accept(p2pEngine, 1000, &acceptChannel);
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
        }
        if (result < 0) {
            // error
            NSLog(@"kkp2p_accept error,listenfd:%d",listenFd);
            return;
        } else if (result == 0) {
            // timeout
            continue;
        } else if (result > 0) {
            // success
            KKP2PChannel* channel = [[KKP2PChannel alloc] init];
            channel->peer_id = [NSString stringWithUTF8String:acceptChannel.peer_id];
            channel->channel_type = acceptChannel.channel_type;
            channel->transmit_mode = acceptChannel.transmit_mode;
            channel->encrypt_data = acceptChannel.encrypt_data;
            channel->channel_id = acceptChannel.channel_id;
            channel->is_ipv6_p2p = acceptChannel.is_ipv6_p2p;
            channel->connect_desc = acceptChannel.connect_desc;
            channel->fd = acceptChannel.fd;
            [acceptChannelArray addObject:channel];
            NSLog(@"accept new channel,fd:%d,accept channel count:%lu,p2pEngine:%p",channel->fd,[acceptChannelArray count],p2pEngine);
            
            // notify success
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary * dic = [[NSDictionary alloc]initWithObjectsAndKeys:@"1",@"eventType",nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyEvent" object:nil userInfo:dic];
            });
            
            [self performSelectorInBackground:@selector(loopReadChannel:) withObject:channel];
            continue;
        }
    }
}

- (int)loopReadChannel: (KKP2PChannel*) channel {
    NSLog(@"loopReadChannel thread start,fd:%d",channel->fd);
    while(TRUE) {
        int messageTag = 0;
        int messageLength = 0;
        int recved = 0;
    
        //first,recv message tag
        recved = [self recvSocketMsg:channel buff:(char*)&messageTag len:sizeof(int)];
        if (recved < 0) {
            return recved;
        }
        messageTag = ntohl(messageTag);
    
        //second,recv message len
        recved = [self recvSocketMsg:channel buff:(char*)&messageLength len:sizeof(int)];
        if (recved <= 0) {
            return recved;
        }
        messageLength = ntohl(messageLength);
    
        if (messageTag == 1) {
            // it's text message
            char* szBuff = (char*)calloc(1, messageLength);
            recved = [self recvSocketMsg:channel buff:szBuff len:messageLength];
            if (recved < 0) {
                return recved;
            }
            NSLog(@"recv text msg：%s",szBuff);
            NSString *message =  [[NSString alloc] initWithUTF8String:szBuff];
            free(szBuff);
            
            // notify success
            NSDictionary * dic = [[NSDictionary alloc]initWithObjectsAndKeys:@"2",@"eventType",message, @"eventMessage",nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyEvent" object:nil userInfo:dic];
        } else if (messageTag == 2) {
            //start tick
            struct timeval tNow;
            gettimeofday(&tNow, NULL);
            UInt64 startMs = (UInt64)tNow.tv_sec * 1000 + (UInt64)tNow.tv_usec / 1000;
            
            // it's file,recv it and discard
            char szBuff[1024];
            int recved = 0 ;
            int expectLen = 0;
            while (recved < messageLength) {
                if (messageLength - recved > 1024) {
                    expectLen = 1024;
                } else {
                    expectLen = messageLength - recved;
                }
                
                int len = [self recvSocketMsg:channel buff:szBuff len:expectLen];
                if (len < 0) {
                    return -1;
                }
                recved += len;
            }
            gettimeofday(&tNow, NULL);
            UInt64 endMs = (UInt64)tNow.tv_sec * 1000 + (UInt64)tNow.tv_usec / 1000;
            int speed = 0;
            if (endMs - startMs > 0) {
                speed = messageLength /((endMs - startMs)/1000);
            }
            
            NSString *message =  [NSString stringWithFormat:@"recv file,len:%d,speed:%d Byte/s,discard it",messageLength,speed];
            // notify success
            NSDictionary * dic = [[NSDictionary alloc]initWithObjectsAndKeys:@"3",@"eventType",message, @"eventMessage",nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyEvent" object:nil userInfo:dic];
        }
    }
    return 0;
}

- (void)processNotification:(NSNotification *)notification {
    // notify success
    NSDictionary  *dic = [notification userInfo];
    NSString *eventType = [dic objectForKey:@"eventType"];
    if([eventType isEqualToString:@"1"]) {
        KKP2PChannel* channel = [acceptChannelArray lastObject];
        if (channel == NULL) {
            return;
        }
        if (channel->transmit_mode == 1) {
            if (channel->is_ipv6_p2p == 1) {
                [_modeButton setTitle:@"p2p(ipv6 accepted)" forState:UIControlStateNormal];
            } else {
                [_modeButton setTitle:@"p2p(ipv4 accepted)" forState:UIControlStateNormal];
            }
        } else {
            [_modeButton setTitle:@"relay(accepted)" forState:UIControlStateNormal];
        }
        _modeButton.enabled = FALSE;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"accept success" message: @"" preferredStyle: UIAlertControllerStyleAlert];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController: alert animated: YES completion: nil];
            [self performSelector:@selector(dismiss:) withObject:alert afterDelay:0.5];
        });
        
    } else if ([eventType isEqualToString:@"2"] || [eventType isEqualToString:@"3"]) {
        // recv msg
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *text = [dic objectForKey:@"eventMessage"];
            [self displayMessageWithContent:text andType:MessageTypeOther];
        });
    } else if ([eventType isEqualToString:@"4"] ) {
        // send msg
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *text = [dic objectForKey:@"eventMessage"];
            [self displayMessageWithContent:text andType:MessageTypeMe];
       });
    }
}

- (void) sendMessageWithContent:(NSString *) text andType:(MessageType) type {
    // write socket
    int result = [self writeMessage:text];
    if (result < 0) {
        return;
    }
    
    [self displayMessageWithContent:text andType:type];
}

- (void) displayMessageWithContent:(NSString *) text andType:(MessageType) type {
    // display message
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MMM-dd hh:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    
    
    NSDictionary *dict = @{@"text":text,
                           @"time":dateStr,
                           @"type":[NSString stringWithFormat:@"%d", type]};
    
    Message *message = [[Message alloc] init];
    [message setValuesForKeysWithDictionary:dict];
    MessageFrame *messageFrame = [[MessageFrame alloc] init];
    messageFrame.message = message;
    
    [self.messages addObject:messageFrame];
    
    // 消除消息框内容
    if (type == MessageTypeMe) {
        self.chatTextField.text = nil;
    }
    
    [self.chatTableView reloadData];
    
    // 滚动到最新的消息
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.chatTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}

- (int)writeMessage:(NSString *) text
{
    P2PEngineContext * ctx = [P2PEngineContext getInstance];
    KKP2PChannel* channel ;
    int send = 0;
    if ([acceptChannelArray count] > 0) {
        channel = [acceptChannelArray lastObject];
        if (channel->fd <= 0) {
            NSLog(@"begin writeMessage,last channel fd < 0:%d,channel count:%ld",channel->fd,[acceptChannelArray count]);
            return -1;
        }
        NSLog(@"begin writeMessage,use accept channel fd:%d",channel->fd);
    }else if (clientChannel->fd > 0) {
        channel = clientChannel;
        NSLog(@"begin writeMessage,use client channel fd:%d,p2pEngine:%p",channel->fd,ctx->p2pEngine);
    } else {
        return -1;
    }
    
    // protocol format is TLV
    
    // first send TAG,1 is text,2 is file
    int messageTag = 1;
    int netTag = htonl(messageTag);
    send = [self sendSocketMsg:channel buff:(char*)&netTag len:sizeof(int)];
    if (send < 0 ) {
        return -1;
    }
    
    // second send LEN
    const char *cString = [text UTF8String];
    int len = strlen(cString);
    int netLen = htonl(len);
    send = [self sendSocketMsg:channel buff:(char*)&netLen len:sizeof(int)];
    if (send < 0 ) {
        return -1;
    }
    
    // send VALUE
    send = [self sendSocketMsg:channel buff:(char*)cString len:len];
    if (send < 0 ) {
        return -1;
    }
    NSLog(@"end writeMessage,send len:%d",send);
    
    return 0;
}

- (int)recvSocketMsg:(KKP2PChannel*)channel
                buff:(char*)szBuff
                len: (int)expectLen
{
    int recv = 0;
    int recved = 0;
    
    // timeout is 5000(ms)
    recv =  kkp2p_read(channel->fd, szBuff, expectLen, 5000);
    if (recv < 0) {
        return -1;
    }
    
    recved += recv;
    while(recved < expectLen) {
        recv =kkp2p_read(channel->fd, szBuff+recved, expectLen-recved, 5000);
        if (recved < 0) {
            return -1;
        }
        recved += recv;
    }
    return recved;
}

- (int)sendSocketMsg:(KKP2PChannel*)channel
                buff:(char*)szBuff
                len: (int)expectLen
{
    int send = 0;
    int sended = 0;
    
    // timeout is 5000(ms)
    send = kkp2p_write(channel->fd, szBuff, expectLen, 5000);
    if (send < 0) {
        return -1;
    }
    
    sended += send;
    while(sended < expectLen) {
        send =kkp2p_write(channel->fd, szBuff+sended, expectLen-sended, 5000);
        if (send < 0) {
            return -1;
        }
        sended += send;
    }
    return sended;
}

- (NSMutableArray *)messages {
    if (nil == _messages) {
        _messages = [[NSMutableArray alloc]init];
    }
    
    return _messages;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  self.messages.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [MessageCell cellWithTableView:self.chatTableView];
    cell.messageFrame = self.messages[indexPath.row];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageFrame *messageFrame = self.messages[indexPath.row];
    return messageFrame.cellHeight;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void) keyboardWillChangeFrame:(NSNotification *) note {
    CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGFloat transformY = keyboardFrame.origin.y - self.view.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, transformY);
    }];
}

/*
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessageWithContent:textField.text andType:MessageTypeMe];
    return YES;
}
 */

- (IBAction)onSendButton:(id)sender {
    [self sendMessageWithContent:_chatTextField.text andType:MessageTypeMe];
}


- (IBAction)onFileButton:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes = @[(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie, (NSString*)kUTTypeVideo];

    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{
    NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    NSURL *fileUrl;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        fileUrl = [info objectForKey:UIImagePickerControllerImageURL];
    } else {
        fileUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // start thread to shend file
    [self performSelectorInBackground:@selector(sendFile:) withObject:fileUrl];
}

-(int) sendFile:(NSURL*)fileUrl {
    NSLog(@"begin sendFile");

    // select write channel
    KKP2PChannel* channel;
    if ([acceptChannelArray count] >0 ) {
        channel = [acceptChannelArray lastObject];
        if (channel->fd < 0 ) {
            return -1;
        }
    } else if (clientChannel->fd > 0) {
        channel = clientChannel;
    } else {
        NSLog(@"begin sendFile not find channel");
        return -1;
    }
    
    int send = 0 ;
    // protocol format is TLV
    // first send TAG,1 is text,2 is file
    int messageTag = 2;
    int netTag = htonl(messageTag);
    send = [self sendSocketMsg:channel buff:(char*)&netTag len:sizeof(int)];
    if (send < 0 ) {
        NSLog(@"begin sendFile tag error,send:%d",send);
        return -1;
    }
    NSLog(@"begin sendFile tag success");
    
    // second send LEN
    // get file size
    NSString *filePath = [fileUrl path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    long long fileSize = [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
    int messageLength = (int)fileSize;  // attenion,only support max int value
    int netLen = htonl(messageLength);
    send = [self sendSocketMsg:channel buff:(char*)&netLen len:sizeof(int)];
    if (send < 0 ) {
        NSLog(@"begin sendFile len error,send:%d",send);
        return -1;
    }
    
    NSLog(@"begin sendFile len success");
    
    // display progress view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.uploadSlider.hidden = FALSE;
        self.fileButton.enabled = FALSE;
    });
    
    // third send VALUE,calculate speed
    //start tick
    struct timeval tNow;
    gettimeofday(&tNow, NULL);
    UInt64 startMs = (UInt64)tNow.tv_sec * 1000 + (UInt64)tNow.tv_usec / 1000;
    
    // stream read file
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: filePath];
    [inputStream open];
    NSInteger maxLength = 1024;
    uint8_t readBuffer[maxLength];
    BOOL endOfStreamReached = NO;
    int sended = 0;
    int readLen = 0;
    while (!endOfStreamReached) {
        NSInteger bytesRead = [inputStream read: readBuffer maxLength:maxLength];
        int readLen = (int)bytesRead;
        if (readLen == 0) {
            endOfStreamReached = YES;
        } else if (readLen == -1) {
            endOfStreamReached = YES;
        } else {
            send = [self sendSocketMsg:channel buff:(char*)readBuffer len:readLen];
            if (send < 0 ) {
                NSLog(@"begin sendFile value error,send:%d",send);
                break;
            }
            sended += readLen;
            
            // update progress view
            dispatch_async(dispatch_get_main_queue(), ^{
                float progress = 1.0 * sended / messageLength;
                [self.uploadSlider setProgress:progress animated:YES];
            });
        }
    }
    [inputStream close];
    
    NSLog(@"send file size:%d,total send len：%d",messageLength,sended);
    
    gettimeofday(&tNow, NULL);
    UInt64 endMs = (UInt64)tNow.tv_sec * 1000 + (UInt64)tNow.tv_usec / 1000;
    int speed = 0;
    if (endMs - startMs > 0) {
        speed = (messageLength/(endMs - startMs))*1000;
    }
    
    NSString *message =  [NSString stringWithFormat:@"send file,len:%d,speed:%d Byte/s",messageLength,speed];
    // notify success
    NSDictionary * dic = [[NSDictionary alloc]initWithObjectsAndKeys:@"4",@"eventType",message, @"eventMessage",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyEvent" object:nil userInfo:dic];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.uploadSlider.hidden = TRUE;
        self.fileButton.enabled = TRUE;
    });
    
    return 0;
}


@end
