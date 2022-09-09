#import "ListCell.h"

@implementation ListCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.frame = CGRectMake(0, 0, 235, 31);
        self.titleLabel = [[UILabel alloc] initWithFrame:self.frame];
        [self.contentView addSubview:self.titleLabel];
        _imageV  = [[UIImageView alloc]initWithFrame:CGRectMake(self.bounds.size.width-30 , 9, 20, 20)];
        [_imageV setImage:[UIImage imageNamed:@"0"]];
        [self addSubview:_imageV];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
