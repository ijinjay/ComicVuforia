#import "BriefViewController.h"

@interface BriefViewController ()
@property (weak, nonatomic) IBOutlet UIButton *finishedButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpace;


@end

@implementation BriefViewController
BOOL isPad() {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _finishedButton.layer.cornerRadius = 5;
    _finishedButton.layer.borderWidth = 1.0;
    if (isPad()) {
        _finishedButton.titleLabel.font = [UIFont systemFontOfSize:60];
        
        _textView.font = [UIFont systemFontOfSize:48];
        _leftSpace.constant = 100;
        _rightSpace.constant = 100;
        _topSpace.constant = 100;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end