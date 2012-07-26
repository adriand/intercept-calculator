//
//  InterceptCalculator.h
//
//  Copyright (c) 2012 Adrian Duyzer
//
//  This class, which is based on the intercept_math.rb class, returns the intercept point
//  (point of intersection) that is created by a line drawn between two points that is extended
//  to touch the edge of the screen.

#import <Foundation/Foundation.h>

@interface InterceptCalculator : NSObject

// This method returns a CGPoint that represents the intercept point between a line drawn from
// a source point through the touch point and a bounding box.  Note that if the touch point is
// the same point as the source point, this will return a point with coordinates -99999,-99999,
// which should really be refactored.
//
// This method was developed while working with cocos2d, which puts the 0,0 coordinate at the bottom
// left.  I have not tested this with other coordinate systems, like the standard iOS coordinate system
// where 0,0 is the top left.
+ (CGPoint)findInterceptFromSource:(CGPoint)source andTouch:(CGPoint)touch withinBounds:(CGRect)bounds;

@end
