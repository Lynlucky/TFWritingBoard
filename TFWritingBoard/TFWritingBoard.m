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

#import "TFWritingBoard.h"

#define kMaxLineWidth 10.0
/**************************************** TFShapeLayer ****************************************/
@interface TFShapeLayer : CAShapeLayer
@end
@implementation TFShapeLayer
- (CGRect)bounds { return CGPathGetBoundingBox(self.path); }
@end
/**************************************** TFShapeLayer ****************************************/

@interface TFWritingBoard ()
#pragma mark - Private Params
/** 当前活动的显示层 */
@property (nonatomic, weak) TFShapeLayer *currentLayer;
/** 当前正在绘制的路径 */
@property (nonatomic, strong) UIBezierPath *currentPath;
@end

@implementation TFWritingBoard
#pragma mark - Public
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.lineWidth = 3.0;
        self.lineColor = [UIColor blackColor];
        self.applePencilOnly = NO;
        self.erasersMode = NO;
    }
    return self;
}
- (UIImage *)getWholeImage {
    if (!self.canClean) return nil;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *wholeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return wholeImage;
}
- (UIImage *)getEffectiveImage {
    UIImage *wholeImage = [self getWholeImage];
    if (wholeImage == nil) return nil;
    CGRect effectiveRect = self.layer.sublayers.firstObject.bounds;
    for (CALayer *layer in self.layer.sublayers) {
        effectiveRect = CGRectUnion(effectiveRect, layer.bounds);
    }
    CGRect clipRect;
    clipRect.origin.x       = wholeImage.scale * floorf(effectiveRect.origin.x - kMaxLineWidth / 2);
    clipRect.origin.y       = wholeImage.scale * floorf(effectiveRect.origin.y - kMaxLineWidth / 2);
    clipRect.size.width     = wholeImage.scale * floorf(effectiveRect.size.width + kMaxLineWidth + 1);
    clipRect.size.height    = wholeImage.scale * floorf(effectiveRect.size.height + kMaxLineWidth + 1);
    CGImageRef cg_image     = CGImageCreateWithImageInRect(wholeImage.CGImage, clipRect);
    UIImage *effectiveImage = [UIImage imageWithCGImage:cg_image scale:wholeImage.scale orientation:wholeImage.imageOrientation];
    CGImageRelease(cg_image);
    return effectiveImage;
}
- (BOOL)canUndo     { return self.undoManager.canUndo; }
- (void)undo        { [self.undoManager undo]; }
- (BOOL)canRedo     { return self.undoManager.canRedo; }
- (void)redo        { [self.undoManager redo]; }
- (BOOL)canClean    { return self.layer.sublayers.count != 0; }
- (void)clean       {
    if (!self.canClean) return;
    NSArray *layers = [self.layer.sublayers copy];
    [self removeLayers:layers previousLayers:layers];
}

#pragma mark - Setter
/** 设置笔宽:[1, 10] */
- (void)setLineWidth:(CGFloat)lineWidth {
    if (lineWidth < 1.0) lineWidth = 1.0;
    if (lineWidth > kMaxLineWidth) lineWidth = kMaxLineWidth;
    _lineWidth = lineWidth;
}

#pragma mark - Undo & Redo actions
/** 添加渲染层 */
- (void)addLayer:(TFShapeLayer *)layer {
    [self.layer addSublayer:layer];
    [[self.undoManager prepareWithInvocationTarget:self] undoAddLayer:layer];
}
/** 撤销添加渲染层 */
- (void)undoAddLayer:(TFShapeLayer *)layer {
    [layer removeFromSuperlayer];
    [[self.undoManager prepareWithInvocationTarget:self] addLayer:layer];
}
/** 移除指定的渲染层列表
 @param layers      将要移除的渲染层列表，必须copy传入
 @Param preLayers   移除前显示的渲染层列表，必须copy传入
 */
- (void)removeLayers:(NSArray <CALayer *> *)layers previousLayers:(NSArray <CALayer *> *)preLayers {
    [[self.undoManager prepareWithInvocationTarget:self] undoRemoveLayers:preLayers nextLayers:layers];
    for (CALayer *layer in layers) [layer removeFromSuperlayer];
}
/** 撤销移除指定的渲染层列表 */
- (void)undoRemoveLayers:(NSArray <CALayer *> *)layers nextLayers:(NSArray <CALayer *> *)nextLayers {
    self.layer.sublayers = layers;
    [[self.undoManager prepareWithInvocationTarget:self] removeLayers:nextLayers previousLayers:layers];
}

#pragma mark - Drawing
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    // 检测是否仅Apple Pencil有效
    if (self.isApplePencilOnly && touch.type != UITouchTypeStylus) return;
    
    CGPoint currentPoint = [touch preciseLocationInView:self];                  // 获取当前触摸的点
    self.currentPath = [UIBezierPath bezierPath];                               // 创建新的贝塞尔路径对象
    [self.currentPath moveToPoint:currentPoint];                                // 设置Path的起始点为当前触摸的点
    if (self.isErasersMode) {// 橡皮擦模式，不显示痕迹
        // 开始橡皮擦的回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(writingBoardWillBeginErasing)])
            [self.delegate writingBoardWillBeginErasing];
        return;
    }
    // 开始笔画的回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(writingBoardWillBeginWriting)])
        [self.delegate writingBoardWillBeginWriting];
    // 起笔时添加一个新的图层，保证每笔都可以独立设置笔宽和笔色
    TFShapeLayer *shapeLayer = [TFShapeLayer layer];
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = self.lineColor.CGColor;
    shapeLayer.lineWidth = self.lineWidth;
    [self addLayer:shapeLayer];
    self.currentLayer = shapeLayer;
    // 渲染笔迹到屏幕上
    self.currentLayer.path = self.currentPath.CGPath;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (self.isApplePencilOnly && touch.type != UITouchTypeStylus) return;

    CGPoint currentPoint = [touch preciseLocationInView:self];
    if (self.isErasersMode) {// 橡皮擦模式，不显示痕迹，所以不需要转角圆滑优化
        [self.currentPath addLineToPoint:currentPoint];
        return;
    }
    // 用二次贝塞尔曲线实现转角圆滑优化
    CGPoint controlPoint = [touch precisePreviousLocationInView:self];          // 获取前一个点作为控制点
    CGPoint endPoint = CGPointMake((controlPoint.x + currentPoint.x) / 2,
                                   (controlPoint.y + currentPoint.y) / 2);      // 取前后两点间的中点作为结束点
    [self.currentPath addQuadCurveToPoint:endPoint controlPoint:controlPoint];  // 当前路径画一条二次贝塞尔曲线
    self.currentLayer.path = self.currentPath.CGPath;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (self.isApplePencilOnly && touch.type != UITouchTypeStylus) return;
    
    CGPoint currentPoint = [touch preciseLocationInView:self];
    [self.currentPath addLineToPoint:currentPoint];
    if (self.isErasersMode) {// 橡皮擦模式，不显示痕迹
        // 获取橡皮擦擦过的区域
        CGRect eraserRect = self.currentPath.bounds;
        // 获取需要擦除的层（这里为了性能使用的是“区域相交法”，“路径相交法”会比较秏性能。）
        NSMutableArray <CALayer *> *selectedLayers = [NSMutableArray array];
        for (CALayer *layer in self.layer.sublayers) {
            if (CGRectIntersectsRect(layer.bounds, eraserRect)) [selectedLayers addObject:layer];
        }
        // 擦除选中的渲染层
        if (selectedLayers.count > 0)
            [self removeLayers:[selectedLayers copy] previousLayers:[self.layer.sublayers copy]];
        // 结束橡皮擦的回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(writingBoardDidEndErased)])
            [self.delegate writingBoardDidEndErased];
        return;
    }
    
    self.currentLayer.path = self.currentPath.CGPath;
    // 结束笔画的回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(writingBoardDidEndWritten)])
        [self.delegate writingBoardDidEndWritten];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 触摸事件被系统事件打断，调用绘制结束操作
    [self touchesEnded:touches withEvent:event];
}

@end
