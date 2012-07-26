//
//  InterceptCalculator.m
//
//  Copyright (c) 2012 Adrian Duyzer
//

#import "InterceptCalculator.h"

typedef BOOL (^PointFilter)(CGPoint);

@implementation InterceptCalculator

+ (CGPoint)findInterceptFromSource:(CGPoint)source andTouch:(CGPoint)touch withinBounds:(CGRect)bounds
{
    NSMutableArray *intercepts = [[NSMutableArray alloc] init];
    
    // In my intercept_math.rb class, bounds has four coordinates.  Here, however, bounds has an origin and a size, so I need to translate
    // into the coordinate types that I need.
    CGFloat boundsLeftX = bounds.origin.x;
    CGFloat boundsRightX = bounds.size.width;
    CGFloat boundsBottomY = bounds.origin.y;
    CGFloat boundsTopY = bounds.size.height;
    
    // using this method to store the CGPoint structs in the intercepts NSMutableArray: http://stackoverflow.com/a/9606903/105650
    
    // check special case #1: touch is on the same spot as the source
    if (source.x == touch.x && source.y == touch.y) {
        // TODO: fix this special case (I can't return nil, unfortunately)...
        return CGPointMake(-99999.0, -99999.0);
    // check special case #2: vertical line
    } else if (source.x == touch.x) {
        [intercepts addObject:[self CGPointValueFromX:source.x andY:boundsBottomY]];
        [intercepts addObject:[self CGPointValueFromX:source.x andY:boundsTopY]];
    // check special case #3: horizontal line
    } else if (source.y == touch.y) {
        [intercepts addObject:[self CGPointValueFromX:boundsLeftX andY:source.y]];
        [intercepts addObject:[self CGPointValueFromX:boundsRightX andY:source.y]];
    // regular cases
    } else {
        // we want to define a line as y = mx + b
        // 1. find the slope of the line: (y2 - y1) / (x2 - x1)
        CGFloat slope = (touch.y - source.y) / (touch.x - source.x);
        // 2. Substitute slope plus one coordinate (we'll use the source's coordinate) into y = mx + b to find b
        // To find b, the equation y = mx + b can be rewritten as b = y - mx
        CGFloat b = source.y - (slope * source.x);
        // We now have what we need to create the equation y = mx + b.  Now we need to find the intercepts.
        // left vertical intercept - we have x, we must solve for y
        CGFloat y = slope * boundsLeftX + b;
        [intercepts addObject:[self CGPointValueFromX:boundsLeftX andY:y]];
        
        // right vertical intercept - we have x, we must solve for y
        y = slope * boundsRightX + b;
        [intercepts addObject:[self CGPointValueFromX:boundsRightX andY:y]];
        
        // bottom horizontal intercept - we have y, we must solve for x
        // x = (y - b) / m
        CGFloat x = (boundsBottomY - b) / slope;
        [intercepts addObject:[self CGPointValueFromX:x andY:boundsBottomY]];
        
        // top horizontal intercept - we have y, we must solve for x
        x = (boundsTopY - b) / slope;
        [intercepts addObject:[self CGPointValueFromX:x andY:boundsTopY]];
    }
    
    [self filterIntercepts:intercepts byBounds:bounds];
    [self filterInterceptsByDirection:intercepts withSource:source andTouch:touch];
    
    CGPoint interceptPoint = [self pointFromValue:[intercepts objectAtIndex:0]];
    return interceptPoint;
}

// This method iterates through the intercepts and send each intercept point into the block.
// The block should return either YES or NO.  If it returns YES, the point is ultimately
// removed from the intercepts.
+ (void)filterIntercepts:(NSMutableArray *)intercepts usingFilterBlock:(PointFilter)filterBlock
{
    NSMutableArray *objectsToRemove = [[NSMutableArray alloc] init];
    CGPoint interceptPoint;
    for (NSValue *pointValue in intercepts) {
        interceptPoint = [self pointFromValue:pointValue];
        if (filterBlock(interceptPoint))
            [objectsToRemove addObject:pointValue];
    }
    [intercepts removeObjectsInArray:objectsToRemove];    
}

+ (void)filterIntercepts:(NSMutableArray *)intercepts byBounds:(CGRect)bounds
{
    // to be a valid intercept, the x value cannot exceed the bounds of the left and right verticals,
    // and the y value cannot exceed the bounds of the bottom and top horizontals
    [self filterIntercepts:intercepts usingFilterBlock:^BOOL(CGPoint point) {
        return (point.x < bounds.origin.x || point.x > (bounds.size.width) || point.y < bounds.origin.y || point.y > bounds.size.height);
    }];
}

// we must determine the correct intercept based on the intended direction of the projectile
+ (void)filterInterceptsByDirection:(NSMutableArray *)intercepts withSource:(CGPoint)source andTouch:(CGPoint)touch
{
    // we must establish the direction that was intended for the touch
    // if the difference between the touch's x and the source's x is positive, then any intercept with an x position that
    // is less than the source's y position is invalid
    CGFloat xDelta = touch.x - source.x;
    if (xDelta >= 0.0) {
        [self filterIntercepts:intercepts usingFilterBlock:^BOOL(CGPoint point) {
            return (point.x < source.x); 
        }];
    } else {
        [self filterIntercepts:intercepts usingFilterBlock:^BOOL(CGPoint point) {
            return (point.x >= source.x); 
        }];        
    }
    
    CGFloat yDelta = touch.y - source.y;
    if (yDelta >= 0.0) {
        [self filterIntercepts:intercepts usingFilterBlock:^BOOL(CGPoint point) {
            return (point.y < source.y); 
        }];
    } else {
        [self filterIntercepts:intercepts usingFilterBlock:^BOOL(CGPoint point) {
            return (point.y >= source.y);
        }];        
    }
}
         
+ (NSValue *)CGPointValueFromX:(CGFloat)x andY:(CGFloat)y
{
    CGPoint point = CGPointMake(x, y);
    return [self valueFromCGPoint:point];
}

+ (NSValue *)valueFromCGPoint:(CGPoint)point
{
    return [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
}

+ (CGPoint)pointFromValue:(NSValue *)pointValue
{
    CGPoint point;
    [pointValue getValue:&point];
    return point;
}

@end
