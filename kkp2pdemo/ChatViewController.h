#import "ViewController.h"
#import "KKP2PChannel.h"

// download url: https://kkuai.com/download/sdk/detail?platform=sdk_ios
#import "kkp2p_sdk.h"

@interface ChatViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    NSString* friendName;
    KKP2PChannel *clientChannel;
    NSMutableArray *acceptChannelArray;
    NSThread* acceptThread;
}

@property(nonatomic, strong) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (weak, nonatomic) IBOutlet UIButton *fileButton;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
@property (weak, nonatomic) IBOutlet UIProgressView *uploadSlider;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end
