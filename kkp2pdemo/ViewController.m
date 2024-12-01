#import "ViewController.h"
#import "ListView.h"
#import "P2PEngineContext.h"
#import "ChatViewController.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"begin ViewController viewDidLoad");
    p2pEngine = NULL;
    
    // init config
    _loginDomain.text = @"124.71.217.198";
    _loginPort.text = @"3080";
    _lanPort.text = @"3549";
    
    // for select conn mode
    [self.connMode addTarget:self action:@selector(buttonClickConn:) forControlEvents:UIControlEventTouchUpInside];
    self.connMode.layer.borderWidth = 1;
    self.connMode.layer.borderColor = [UIColor colorWithRed:235.0/255 green:234.0/255 blue: 234.0/255 alpha:1].CGColor;
    self.connMode.layer.cornerRadius = 6;
    
    self.connModeData = [NSMutableArray array];
    [_connModeData addObject:@"auto|0"];
    [_connModeData addObject:@"p2p|1"];
    [_connModeData addObject:@"relay|2"];
    [_connModeData addObject:@"lanSearch"];
    
    // for select login account
    [self.accountInfo addTarget:self action:@selector(buttonClickAccount:) forControlEvents:UIControlEventTouchUpInside];
    self.accountInfo.layer.borderWidth = 1;
    self.accountInfo.layer.borderColor = [UIColor colorWithRed:235.0/255 green:234.0/255 blue: 234.0/255 alpha:1].CGColor;
    self.accountInfo.layer.cornerRadius = 6;
    
    self.accountData = [NSMutableArray array];
    [_accountData addObject:@"kkuai-ipc-00001|WtXmjG"];
    [_accountData addObject:@"kkuai-ipc-00002|OBq26M"];
    
    // login Button
    [self.loginButton addTarget:self action:@selector(onLoginButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonClickConn:(UIButton *)btn{
    CGFloat f;
    if(listViewConn == nil) {
        if (_connModeData.count < 5) {
            f = 40*_connModeData.count;
        }else{
            f = 120;
        }
        listViewConn = [[ListView alloc]initWithShowDropDown:btn :f :_connModeData:1];
        listViewConn.delegate = self;
    }
    else {
        [listViewConn hideDropDown:btn];
        listViewConn = nil;
    }
}

- (void)buttonClickAccount:(UIButton *)btn{
    CGFloat f;
    if(listViewAccount == nil) {
        if (_accountData.count < 3) {
            f = 40*_accountData.count;
        }else{
            f = 120;
        }
        listViewAccount = [[ListView alloc]initWithShowDropDown:btn :f :_accountData:2];
        listViewAccount.delegate = self;
    }
    else {
        [listViewAccount hideDropDown:btn];
        listViewAccount = nil;
    }
}

- (void)dropDownDelegateMethod: (ListView *) sender {
    if (sender->downType == 1) {
        listViewConn = nil;
    } else if (sender->downType == 2) {
        listViewAccount = nil;
    }
}

- (void)onLoginButton:(UIButton *)btn{
    NSLog(@"begin ViewController onLoginButton");
    // init kkp2p_engine_conf_t
    kkp2p_engine_conf_t engineConf;
    memset(&engineConf, 0, sizeof(engineConf));
    const char *cString = [_loginDomain.text UTF8String];
    engineConf.login_domain = (char*)cString;
    engineConf.login_port = [_loginPort.text intValue];
    engineConf.lan_search_port = [_lanPort.text intValue];
    
    // timeout is used to resolve login domain
    if (p2pEngine != NULL) {
        NSLog(@"kkp2p_engine_destroy p2pEngine:%p",p2pEngine);
        kkp2p_engine_destroy(p2pEngine);
        p2pEngine = NULL;
    }
    p2pEngine = kkp2p_engine_init(&engineConf, 5000); // 5000ms
    if (p2pEngine == NULL) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"error" message: @"login failure" preferredStyle: UIAlertControllerStyleAlert];
        [self presentViewController: alert animated: YES completion: nil];
        [self performSelector:@selector(dismiss:) withObject:alert afterDelay:0.5];
    }
    NSLog(@"new p2pEngine:%p",p2pEngine);
    
    // get login name and secret,and join to the p2p cloud net and p2p lan net
    NSArray *array = [_accountInfo.titleLabel.text componentsSeparatedByString:@"|"];
    NSString *account = [array firstObject];
    const char* szAccount = [account UTF8String];
    const char* szSecret = [[array lastObject] UTF8String];
    kkp2p_join_net(p2pEngine, (char*)szAccount, (char*)szSecret);
    kkp2p_join_lan(p2pEngine, (char*)szAccount);
    
    // init p2p engine context param
    P2PEngineContext * ctx = [P2PEngineContext getInstance ];
    ctx->loginDomain =  [NSString stringWithString:_loginDomain.text];
    ctx->loginPort =  [NSString stringWithString:_loginPort.text];
    ctx->lanSearchPort =  [NSString stringWithString:_lanPort.text];
    ctx->connMode = [NSString stringWithString:_connMode.titleLabel.text];
    ctx->loginName = [NSString stringWithString:account];
    ctx->p2pEngine = p2pEngine;
    
    // jump to chat view controler
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *vc1 = [sb instantiateViewControllerWithIdentifier:@"Chat"];
    [self presentViewController:vc1 animated:YES completion:^{}];
}

- (void)dismiss:(UIAlertController *)alert {
    [alert dismissViewControllerAnimated: YES completion: nil];
}

@end
