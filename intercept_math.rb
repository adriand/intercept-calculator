#!/usr/bin/ruby

# This demonstration code was developed while working with cocos2d, which puts the 0,0 coordinate at the bottom
# left.  I have not tested this with other coordinate systems, like the standard iOS coordinate system
# where 0,0 is the top left.  Additionally, the dimensions of the bounding box are hard-coded here to be 1024x768.
# Those dimensions can be easily changed in the find_intercept method.

def find_intercept(source, touch)
  # the dimensions of the screen are 1024 x 768
  # Cocos2d puts the 0,0 origin at the bottom left, which is good
  # so, the four lines that define the borders of the screen are:
  bounds = {
    :left =>    { :x => 0.0 },
    :right =>   { :x => 1024.0 },
    :bottom =>  { :y => 0.0 },
    :top =>     { :y => 768.0 }
  }

  intercepts = []

  # check special case #1: touch is on the same spot as the source
  if source[:x] == touch[:x] && source[:y] == touch[:y]
    # this is an invalid case, so return nil
    return nil
  # check special case #2: vertical line
  elsif source[:x] == touch[:x]
    intercepts << { :x => source[:x], :y => bounds[:bottom][:y] }
    intercepts << { :x => source[:x], :y => bounds[:top][:y] }
  # check special case #3: horizontal line
  elsif source[:y] == touch[:y]
    intercepts << { :x => bounds[:left][:x], :y => source[:y] }
    intercepts << { :x => bounds[:right][:x], :y => source[:y] }
  # regular cases
  else
    # we want to define a line as y = mx + b
    # 1. find the slope of the line: (y2 - y1) / (x2 - x1)
    slope = (touch[:y] - source[:y]) / (touch[:x] - source[:x])
    # 2. Substitute slope plus one coordinate (we'll use the source's coordinate) into y = mx + b to find b
    # To find b, the equation y = mx + b can be rewritten as b = y - mx
    b = source[:y] - (slope * source[:x])
    # We now have what we need to create the equation y = mx + b.  Now we need to find the intercepts.

    # left vertical intercept - we have x, we must solve for y
    y = slope * bounds[:left][:x] + b
    intercepts << { :x => bounds[:left][:x], :y => y }

    # right vertical intercept - we have x, we must solve for y
    y = slope * bounds[:right][:x] + b
    intercepts << { :x => bounds[:right][:x], :y => y }

    # bottom horizontal intercept - we have y, we must solve for x
    # x = (y - b) / m
    x = (bounds[:bottom][:y] - b) / slope
    intercepts << { :x => x, :y => bounds[:bottom][:y] }

    # top horizontal intercept - we have y, we must solve for x
    x = (bounds[:top][:y] - b) / slope
    intercepts << { :x => x, :y => bounds[:top][:y] }
  end

  bounds_filter(bounds, intercepts)
  directional_filter(source, touch, intercepts)

  # we're only ever interested in a single intercept
  intercepts.first
end

def bounds_filter(bounds, intercepts)
  # to be a valid intercept, the x value cannot exceed the bounds of the left and right verticals,
  # and the y value cannot exceed the bounds of the bottom and top horizontals
  intercepts.delete_if do |intercept|
    intercept[:x] < bounds[:left][:x] ||
      intercept[:x] > bounds[:right][:x] ||
      intercept[:y] < bounds[:bottom][:y] ||
      intercept[:y] > bounds[:top][:y]
  end
end

# we must determine the correct intercept based on the intended direction of the projectile
def directional_filter(source, touch, intercepts)
  # we must establish the direction that was intended for the touch
  # if the difference between the touch's x and the source's x is positive, then any intercept with an x position that
  # is less than the source's y position is invalid and vice versa
  x_delta = touch[:x] - source[:x]
  if x_delta >= 0
    intercepts.delete_if { |intercept| intercept[:x] < source[:x] }
  else
    intercepts.delete_if { |intercept| intercept[:x] >= source[:x] }
  end
  # if the difference between the touch's y and the source's y is positive, then any intercept with a y position that
  # is less than the source's y position is invalid and vice versa
  y_delta = touch[:y] - source[:y]
  if y_delta >= 0
    intercepts.delete_if { |intercept| intercept[:y] < source[:y] }
  else
    intercepts.delete_if { |intercept| intercept[:y] >= source[:y] }
  end
end

def print_intercept(source, touch, intercept)
  puts "source: #{source[:x]}, #{source[:y]} Touch: #{touch[:x]}, #{touch[:y]} Intercept: #{intercept[:x]}, #{intercept[:y]}"
end

# let's assume a source position around the middle of the screen
source =        { :x => 500.0, :y => 350.0 }

# and touches that are all over the place
touches = [
  { :x => 100.0, :y => 100.0 },
  { :x => 50.0, :y => 400.0 },
  { :x => 450.0, :y => 800.0 },
  { :x => 700.0, :y => 25.0 },
  { :x => 500.0, :y => 400.0 }, # special case: vertical line
  { :x => 950, :y => 350.0 }, # special case: horizontal line
  { :x => 500.0, :y => 350.0 } # special case: same point as source
]

touches.each do |touch|
  intercept = find_intercept(source, touch)
  if intercept
    print_intercept(source, touch, intercept)
  end
end
