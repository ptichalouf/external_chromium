// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include "base/scoped_nsobject.h"
#import "chrome/browser/cocoa/cocoa_test_helper.h"
#import "chrome/browser/cocoa/find_bar_view.h"
#include "chrome/browser/cocoa/test_event_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

@interface MouseDownViewPong : NSView {
  BOOL pong_;
}
@property (nonatomic, assign) BOOL pong;
@end

@implementation MouseDownViewPong
@synthesize pong = pong_;
- (void)mouseDown:(NSEvent*)event {
  pong_ = YES;
}
@end


namespace {

class FindBarViewTest : public CocoaTest {
 public:
  FindBarViewTest() {
    NSRect frame = NSMakeRect(0, 0, 100, 30);
    scoped_nsobject<FindBarView> view(
        [[FindBarView alloc] initWithFrame:frame]);
    view_ = view.get();
    [[test_window() contentView] addSubview:view_];
  }

  FindBarView* view_;
};

TEST_VIEW(FindBarViewTest, view_)

TEST_F(FindBarViewTest, FindBarEatsMouseClicksInBackgroundArea) {
  scoped_nsobject<MouseDownViewPong> pongView(
      [[MouseDownViewPong alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)]);

  // Remove all of the subviews of the findbar, to make sure we don't
  // accidentally hit a subview when trying to simulate a click in the
  // background area.
  [view_ setSubviews:[NSArray array]];
  [view_ setFrame:NSMakeRect(0, 0, 200, 200)];

  // Add the pong view as a sibling of the findbar.
  [[test_window() contentView] addSubview:pongView.get()
                               positioned:NSWindowBelow
                               relativeTo:view_];

  // Synthesize a mousedown event and send it to the window.  The event is
  // placed in the center of the find bar.
  NSPoint pointInCenterOfFindBar = NSMakePoint(100, 100);
  [pongView setPong:NO];
  [test_window()
      sendEvent:test_event_utils::LeftMouseDownAtPoint(pointInCenterOfFindBar)];
  // Click gets eaten by findbar, not passed through to underlying view.
  EXPECT_FALSE([pongView pong]);
}

TEST_F(FindBarViewTest, FindBarPassesThroughClicksInTransparentArea) {
  scoped_nsobject<MouseDownViewPong> pongView(
      [[MouseDownViewPong alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)]);
  [view_ setFrame:NSMakeRect(0, 0, 200, 200)];

  // Add the pong view as a sibling of the findbar.
  [[test_window() contentView] addSubview:pongView.get()
                               positioned:NSWindowBelow
                               relativeTo:view_];

  // Synthesize a mousedown event and send it to the window.  The event is inset
  // a few pixels from the lower left corner of the window, which places it in
  // the transparent area surrounding the findbar.
  NSPoint pointInTransparentArea = NSMakePoint(2, 2);
  [pongView setPong:NO];
  [test_window()
      sendEvent:test_event_utils::LeftMouseDownAtPoint(pointInTransparentArea)];
  // Click is ignored by findbar, passed through to underlying view.
  EXPECT_TRUE([pongView pong]);
}
}  // namespace