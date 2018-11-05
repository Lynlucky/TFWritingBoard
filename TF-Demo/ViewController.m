//
//  ViewController.m
//  TF-Demo
//
//  Created by teanfoo on 2018/8/2.
//  Copyright © 2018年 teanfoo. All rights reserved.
//

#import "ViewController.h"
#import "TFWritingBoard.h"


#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height
#define HALF_SCREEN_W ([UIScreen mainScreen].bounds.size.width/2)
#define HALF_SCREEN_H ([UIScreen mainScreen].bounds.size.height/2)
// 是否为iPad
#define kIsiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
// 判断是否为刘海屏
#define kIsAbnormityiPhone  (SCREEN_H == 812.0 || SCREEN_H == 896.0)
// 状态栏高度
#define kStatusBarHeight    (kIsAbnormityiPhone ? 44.0 : 20.0)
// 导航栏高度
#define kNavBarHeight       44.0
// TabBar高度
#define kTabBarHeight       (kIsAbnormityiPhone ? 83.0 : 49.0)
// 状态栏和导航栏总高度
#define kNavBarMaxHeight    (kIsAbnormityiPhone ? 88.0 : 64.0)
// 顶部安全区域远离高度
#define kTopSafeHeight      (kIsAbnormityiPhone ? 44.0 : 0.0)
// 底部安全区域远离高度
#define kBottomSafeHeight   (kIsAbnormityiPhone ? 34.0 : 0.0)

@interface ViewController () <TFWritingBoardDelegate>

@property (nonatomic, weak) TFWritingBoard *writingBoard;
@property (nonatomic, weak) UIView *widthAdjustmentView;
@property (nonatomic, weak) UIView *colorSelectionView;
@property (nonatomic, weak) UIButton *eraserBtn;
@property (nonatomic, weak) UIButton *exportBtn;
@property (nonatomic, weak) UIButton *cleanButton;
@property (nonatomic, weak) UIButton *undoButton;
@property (nonatomic, weak) UIButton *redoButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor grayColor];
    // 添加写字板
    self.writingBoard.hidden = NO;
    // 添加按钮
    self.widthAdjustmentView.hidden = NO;
    self.colorSelectionView.hidden = NO;
    self.eraserBtn.hidden = NO;
    self.exportBtn.hidden = NO;
    self.cleanButton.hidden = NO;
    self.undoButton.hidden = NO;
    self.redoButton.hidden = NO;
}
/** 更新操作按钮的状态 */
- (void)updateToolButtonStatus {
    // 根据是否可以执行清除操作来修改导出全图按钮的状态
    self.exportBtn.enabled = self.writingBoard.canClean;
    // 根据是否可以执行清除操作来修改清除按钮的状态
    self.cleanButton.enabled = self.writingBoard.canClean;
    // 根据是否可以执行撤销操作来修改撤销按钮的状态
    self.undoButton.enabled = self.writingBoard.canUndo;
    // 根据是否可以执行重做操作来修改重做按钮的状态
    self.redoButton.enabled = self.writingBoard.canRedo;
}

#pragma mark - TFWritingBoardDelegate
- (void)writingBoardDidEndWritten {
    // 更新操作按钮的状态
    [self updateToolButtonStatus];
}
- (void)writingBoardDidEndErased {
    // 更新操作按钮的状态
    [self updateToolButtonStatus];
}

#pragma mark - 滑杆的滑动事件
- (void)handleSlider:(UISlider *)slider {
    CGFloat width = floorf(slider.value);
    if (width == self.writingBoard.lineWidth) return;   // 未改变宽度
    self.writingBoard.lineWidth = width;
}
#pragma mark - 颜色切换事件
- (void)onColorBlockClicked:(UIControl *)sender {
    if (sender.layer.borderWidth == 2.0) return;        // 未改变颜色
    // 取消所有选中状态
    for (UIView *view in self.colorSelectionView.subviews) {
        view.layer.borderWidth = 0.0;
    }
    // 标记当前选中的颜色
    sender.layer.borderWidth = 2.0;
    // 设置笔画的颜色
    self.writingBoard.lineColor = sender.backgroundColor;
}
#pragma mark - 操作按钮点击事件
- (void)onBtnClicked:(UIButton *)sender {
    
    if (sender.tag == 0) {          // 橡皮擦开关
        sender.selected = !sender.isSelected;
        self.writingBoard.erasersMode = sender.isSelected;
    } else if (sender.tag == 1) {   // 导出
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"请选择导出类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        __weak typeof(self) weakSelf = self;
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"导出完整的图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { // 导出完整的图片
            UIImage *image = [weakSelf.writingBoard getWholeImage];
            NSLog(@"image: %@", image);
        }]];
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"导出有效区域图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { // 导出有效区域图片
            UIImage *image = [weakSelf.writingBoard getEffectiveImage];
            NSLog(@"image: %@", image);
        }]];
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        if (kIsiPad) {
            actionSheet.popoverPresentationController.sourceRect = sender.frame;
            actionSheet.popoverPresentationController.sourceView = sender;
        }
        [self presentViewController:actionSheet animated:YES completion:nil];
    } else if (sender.tag == 2) {   // 撤销
        [self.writingBoard undo];
    } else if (sender.tag == 3){    // 清除
        [self.writingBoard clean];
    } else if (sender.tag == 4) {   // 重做
        [self.writingBoard redo];
    }
    // 更新操作按钮的状态
    [self updateToolButtonStatus];
}

#pragma mark - Getter
- (TFWritingBoard *)writingBoard {
    if (_writingBoard == nil) {
        TFWritingBoard *writingBoard = [[TFWritingBoard alloc] initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H - 210 - kBottomSafeHeight)];
        writingBoard.backgroundColor = [UIColor whiteColor];
        writingBoard.delegate = self;
        writingBoard.lineWidth = 2.0;
        writingBoard.lineColor = [UIColor blackColor];
        // writingBoard.applePencilOnly = YES;
        [self.view addSubview:writingBoard];
        _writingBoard = writingBoard;
    }
    return _writingBoard;
}
- (UIView *)widthAdjustmentView {
    if (_widthAdjustmentView == nil) {
        UIView *widthAdjustmentView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_H - 200 - kBottomSafeHeight, SCREEN_W, 49)];
        widthAdjustmentView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:widthAdjustmentView];
        _widthAdjustmentView = widthAdjustmentView;
        
        // 添加提示Label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(widthAdjustmentView.bounds), 15)];
        label.textColor = [UIColor lightGrayColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"选择笔画宽度";
        [widthAdjustmentView addSubview:label];
        
        CGFloat positionY = CGRectGetHeight(label.bounds);
        CGFloat sliderWidth = SCREEN_W - 60;
        CGFloat sliderHeight = CGRectGetHeight(widthAdjustmentView.bounds) - positionY;
        // 添加左边的提示Label
        UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY, (SCREEN_W - sliderWidth) / 2, sliderHeight)];
        minLabel.textColor = [UIColor darkTextColor];
        minLabel.font = [UIFont systemFontOfSize:10.0];
        minLabel.textAlignment = NSTextAlignmentCenter;
        minLabel.text = @"1";
        [widthAdjustmentView addSubview:minLabel];
        // 添加滑杆
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake((SCREEN_W - sliderWidth) / 2, positionY, sliderWidth, sliderHeight)];
        slider.backgroundColor = [UIColor whiteColor];
        slider.minimumTrackTintColor = [UIColor greenColor];    // 设置滑竿滑过部分的颜色
        slider.maximumTrackTintColor = [UIColor grayColor];     // 设置滑竿未滑过部分的颜色
        slider.minimumValue = 1.0;                              // 设置滑竿滑动的数值区间的最小值
        slider.maximumValue = 10.0;                             // 设置滑竿滑动的数值区间的最大值
        slider.value = 2.0;                                     // 设置滑动按钮默认出现所在的位置
        [slider addTarget:self action:@selector(handleSlider:) forControlEvents:UIControlEventValueChanged];
        [widthAdjustmentView addSubview:slider];
        // 添加右边的提示Label
        UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(slider.frame), positionY, (SCREEN_W - sliderWidth) / 2, sliderHeight)];
        maxLabel.textColor = [UIColor darkTextColor];
        maxLabel.font = [UIFont systemFontOfSize:10.0];
        maxLabel.textAlignment = NSTextAlignmentCenter;
        maxLabel.text = @"10";
        [widthAdjustmentView addSubview:maxLabel];
    }
    return _colorSelectionView;
}
- (UIView *)colorSelectionView {
    if (_colorSelectionView == nil) {
        UIView *colorSelectionView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_H - 150 - kBottomSafeHeight, SCREEN_W, 59)];
        colorSelectionView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:colorSelectionView];
        _colorSelectionView = colorSelectionView;
        
        // 添加提示Label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(colorSelectionView.bounds), 15)];
        label.textColor = [UIColor lightGrayColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"选择笔画颜色";
        [colorSelectionView addSubview:label];
        // 添加色块按钮
        CGFloat itemWidth = 60.0, itemHeight = 40.0, itemGap = 30.0;
        int itemCount = 3;
        CGFloat positionX = (SCREEN_W - itemWidth * itemCount - itemGap * (itemCount - 1)) / 2;
        for (int i=0; i<itemCount; i++) {
            UIControl *item = [[UIControl alloc] initWithFrame:CGRectMake(positionX, 18, itemWidth, itemHeight)];
            item.layer.borderColor = [[UIColor greenColor] CGColor];
            if (0 == i) {
                // 黑色（默认选中）
                item.backgroundColor = [UIColor blackColor];
                item.layer.borderWidth = 2.0;
            } else if (1 == i) {
                // 红色
                item.backgroundColor = [UIColor redColor];
                item.layer.borderWidth = 0.0;
            } else {
                // 蓝色
                item.backgroundColor = [UIColor blueColor];
                item.layer.borderWidth = 0.0;
            }
            [item addTarget:self action:@selector(onColorBlockClicked:) forControlEvents:UIControlEventTouchUpInside];
            [colorSelectionView addSubview:item];
            positionX += itemWidth + itemGap;
        }
    }
    return _colorSelectionView;
}

- (UIButton *)eraserBtn {
    if (_eraserBtn == nil) {
        UIButton *eraserBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_H - 90 - kBottomSafeHeight, HALF_SCREEN_W, 44)];
        eraserBtn.backgroundColor = [UIColor purpleColor];
        eraserBtn.tag = 0;
        eraserBtn.selected = NO;
        [eraserBtn setTitle:@"橡皮擦：关闭" forState:UIControlStateNormal];
        [eraserBtn setTitle:@"橡皮擦：开启" forState:UIControlStateSelected];
        [eraserBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [eraserBtn addTarget:self action:@selector(onBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:eraserBtn];
        _eraserBtn = eraserBtn;
    }
    return _eraserBtn;
}
- (UIButton *)exportBtn {
    if (_exportBtn == nil) {
        UIButton *exportBtn = [[UIButton alloc] initWithFrame:CGRectMake(HALF_SCREEN_W, SCREEN_H - 90 - kBottomSafeHeight, HALF_SCREEN_W, 44)];
        exportBtn.backgroundColor = [UIColor brownColor];
        exportBtn.tag = 1;
        exportBtn.enabled = NO;
        [exportBtn setTitle:@"导出图片" forState:UIControlStateNormal];
        [exportBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [exportBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [exportBtn addTarget:self action:@selector(onBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:exportBtn];
        _exportBtn = exportBtn;
    }
    return _exportBtn;
}

- (UIButton *)cleanButton {
    if (_cleanButton == nil) {
        UIButton *cleanButton = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_H - 45 - kBottomSafeHeight, SCREEN_W, 45)];
        cleanButton.backgroundColor = [UIColor whiteColor];
        cleanButton.tag = 3;
        cleanButton.enabled = NO;
        [cleanButton setTitle:@"清除" forState:UIControlStateNormal];
        [cleanButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [cleanButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [cleanButton addTarget:self action:@selector(onBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:cleanButton];
        _cleanButton = cleanButton;
    }
    return _cleanButton;
}
- (UIButton *)undoButton {
    if (_undoButton == nil) {
        UIButton *undoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_H - 45 - kBottomSafeHeight, SCREEN_W / 3, 45)];
        undoButton.backgroundColor = [UIColor greenColor];
        undoButton.tag = 2;
        undoButton.enabled = NO;
        [undoButton setTitle:@"撤销" forState:UIControlStateNormal];
        [undoButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [undoButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [undoButton addTarget:self action:@selector(onBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:undoButton];
        _undoButton = undoButton;
    }
    return _undoButton;
}
- (UIButton *)redoButton {
    if (_redoButton == nil) {
        UIButton *redoButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_W * 2 / 3, SCREEN_H - 45 - kBottomSafeHeight, SCREEN_W / 3, 45)];
        redoButton.backgroundColor = [UIColor cyanColor];
        redoButton.tag = 4;
        redoButton.enabled = NO;
        [redoButton setTitle:@"重做" forState:UIControlStateNormal];
        [redoButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [redoButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [redoButton addTarget:self action:@selector(onBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:redoButton];
        _redoButton = redoButton;
    }
    return _redoButton;
}

@end

