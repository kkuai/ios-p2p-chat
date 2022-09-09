#import <UIKit/UIKit.h>
#import "ListView.h"

// download url: https://kkuai.com/download/sdk/detail?platform=sdk_ios
#import "kkp2p_sdk.h"
@interface ViewController : UIViewController<ZCDropDownDelegate>{
    ListView *listViewConn;
    ListView *listViewAccount;
    kkp2p_engine_t* p2pEngine;
}

@property (nonatomic, retain)NSMutableArray *connModeData;
@property (nonatomic, retain)NSMutableArray *accountData;

@property (weak, nonatomic) IBOutlet UITextField *loginDomain;
@property (weak, nonatomic) IBOutlet UITextField *loginPort;
@property (weak, nonatomic) IBOutlet UITextField *lanPort;
@property (weak, nonatomic) IBOutlet UIButton *connMode;
@property (weak, nonatomic) IBOutlet UIButton *accountInfo;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

