/**
 The MIT License (MIT)
 
 Copyright (c) 2018 TFWritingBoard (https://github.com/teanfoo/TFWritingBoard)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */
/** 版本信息
 Version:   1.0
 Date:      2018.08.02
 Target:    iOS 8.0 Later
 Changes:   (【A】新增，【D】删除，【M】修改，【F】修复Bug)
 1.【A】初始版本。
 */

#import <UIKit/UIKit.h>

@protocol TFWritingBoardDelegate <NSObject>
@optional
- (void)writingBoardWillBeginWriting;
- (void)writingBoardDidEndWritten;
- (void)writingBoardWillBeginErasing;
- (void)writingBoardDidEndErased;

@end

@interface TFWritingBoard : UIView

/** 代理对象 */
@property (nonatomic, weak) id <TFWritingBoardDelegate> delegate;
/** 笔迹宽度，默认为3.0，范围:[1,10] */
@property (nonatomic, assign) CGFloat lineWidth;
/** 笔迹颜色，默认为黑色 */
@property (nonatomic, strong) UIColor *lineColor;
/** 是否只能用笔(Apple Pencil)写，默认为NO */
@property (nonatomic, assign, getter=isApplePencilOnly) BOOL applePencilOnly;
/** 是否开启橡皮擦模式，默认为NO */
@property (nonatomic, assign, getter=isErasersMode) BOOL erasersMode;

/** 是否可以执行清除操作 */
@property (nonatomic, readonly) BOOL canClean;
/** 清除 */
- (void)clean;
/** 是否可以执行撤销操作 */
@property (nonatomic, readonly) BOOL canUndo;
/** 撤销 */
- (void)undo;
/** 是否可以执行重做操作 */
@property (nonatomic, readonly) BOOL canRedo;
/** 重做 */
- (void)redo;

/** 获取完整的图片 */
- (UIImage *)getWholeImage;
/** 获取有效区域的图片 */
- (UIImage *)getEffectiveImage;

@end
