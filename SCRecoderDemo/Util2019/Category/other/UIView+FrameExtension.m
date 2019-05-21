//
//  UIView+FrameExtension.m
//  SimpleItemView
//
//  Created by zhuzhijia on 2017/10/20.
//  Copyright © 2017年 zhuzhijia. All rights reserved.
//

#import "UIView+FrameExtension.h"

////获取 中心点
//CGPoint CGRectGetCenter(CGRect rect)
//{
//    CGPoint pt;
//    pt.x = CGRectGetMidX(rect);
//    pt.y = CGRectGetMidY(rect);
//    return pt;
//}
////重新设置rect 的中心点
//CGRect CGRectMoveToCenter(CGRect rect, CGPoint center)
//{
//    CGRect newrect = CGRectZero;
//    newrect.origin.x = center.x-CGRectGetMidX(rect);
//    newrect.origin.y = center.y-CGRectGetMidY(rect);
//    newrect.size = rect.size;
//    return newrect;
//}
////上面两个系统 已经提供 不需要写 直接用view.center即可 同view.frame一样

@implementation UIView (FrameExtension)
- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGFloat)maxX
{
    return self.x + self.width;
}

- (CGFloat)maxY
{
    return self.y + self.height;
}

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right-frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


- (CGPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

// Move via offset
- (void) moveBy: (CGPoint) delta
{
    CGPoint newcenter = self.center;
    newcenter.x += delta.x;
    newcenter.y += delta.y;
    self.center = newcenter;
}

// Scaling
- (void) scaleBy: (CGFloat) scaleFactor
{
    CGRect newframe = self.frame;
    newframe.size.width *= scaleFactor;
    newframe.size.height *= scaleFactor;
    self.frame = newframe;
}

// Ensure that both dimensions fit within the given size by scaling down
- (void) fitInSize: (CGSize) aSize
{
    CGFloat scale;
    CGRect newframe = self.frame;
    
    if (newframe.size.height && (newframe.size.height > aSize.height))
    {
        scale = aSize.height / newframe.size.height;
        newframe.size.width *= scale;
        newframe.size.height *= scale;
    }
    
    if (newframe.size.width && (newframe.size.width >= aSize.width))
    {
        scale = aSize.width / newframe.size.width;
        newframe.size.width *= scale;
        newframe.size.height *= scale;
    }
    
    self.frame = newframe;
}

/** 设置锚点 */
- (CGPoint)py_setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint oldOrigin = view.frame.origin;
    view.layer.anchorPoint = anchorPoint;
    CGPoint newOrigin = view.frame.origin;
    
    CGPoint transition;
    transition.x = newOrigin.x - oldOrigin.x;
    transition.y = newOrigin.y - oldOrigin.y;
    
    view.center = CGPointMake (view.center.x - transition.x, view.center.y - transition.y);
    return self.layer.anchorPoint;
}

/** 根据手势触摸点修改相应的锚点，就是沿着触摸点做相应的手势操作 */
- (CGPoint)py_setAnchorPointBaseOnGestureRecognizer:(UIGestureRecognizer *)gr
{
    // 手势为空 直接返回
    if (!gr) return CGPointMake(0.5, 0.5);
    
    // 创建锚点
    CGPoint anchorPoint = CGPointMake(0.5, 0.5);;
    if ([gr isKindOfClass:[UIPinchGestureRecognizer class]]) { // 捏合手势
        if (gr.numberOfTouches == 2) {
            // 当触摸开始时，获取两个触摸点
            CGPoint point1 = [gr locationOfTouch:0 inView:gr.view];
            CGPoint point2 = [gr locationOfTouch:1 inView:gr.view];
            anchorPoint.x = (point1.x + point2.x) / 2 / gr.view.width;
            anchorPoint.y = (point1.y + point2.y) / 2 / gr.view.height;
        }
    } else if ([gr isKindOfClass:[UITapGestureRecognizer class]]) { // 点击手势
        // 获取触摸点
        CGPoint point = [gr locationOfTouch:0 inView:gr.view];
        
        CGFloat angle = acosf(gr.view.transform.a);
        if (ABS(asinf(gr.view.transform.b) + M_PI_2) < 0.01) angle += M_PI;
        CGFloat width = gr.view.width;
        CGFloat height = gr.view.height;
        if (ABS(angle - M_PI_2) <= 0.01 || ABS(angle - M_PI_2 * 3) <= 0.01) { // 旋转角为90°
            // width 和 height 对换
            width = gr.view.height;
            height = gr.view.width;
        }
        // 如果旋转了
        anchorPoint.x = point.x / width;
        anchorPoint.y = point.y / height;
    }
    return [self py_setAnchorPoint:anchorPoint forView:self];
}


/******其它功能****/
//获取nsuserDefault中的内容
-(NSString*)getStringFromUserDefaultForKey:(NSString*)key
{
    NSUserDefaults* myuserDefault = [NSUserDefaults standardUserDefaults];
    NSString* str =  [myuserDefault objectForKey:key];
    [myuserDefault synchronize];
    return str;
}

-(NSArray*)getArrayFromUserDefaultForKey:(NSString*)key
{
    NSUserDefaults* myuserDefault = [NSUserDefaults standardUserDefaults];
    NSArray* array =  [myuserDefault objectForKey:key];
    [myuserDefault synchronize];
    return array;
}

-(NSDictionary*)getDicFromUserDefaultForKey:(NSString*)key
{
    NSUserDefaults* myuserDefault = [NSUserDefaults standardUserDefaults];
    NSDictionary* dic =  [myuserDefault objectForKey:key];
    [myuserDefault synchronize];
    return dic;
}

@end
