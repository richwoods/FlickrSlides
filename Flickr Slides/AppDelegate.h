//
//  AppDelegate.h
//  Flickr Slides
//
//  Created by Jason Terhorst on 8/30/15.
//  Copyright (c) 2015 Jason Terhorst. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, weak) IBOutlet NSPopUpButton * albumList;
@property (nonatomic, weak) IBOutlet NSProgressIndicator * albumSpinner;
@property (nonatomic, weak) IBOutlet NSButton * loopingCheckbox;
@property (nonatomic, weak) IBOutlet NSTextField * outputLabel;
@property (nonatomic, weak) IBOutlet NSButton * exportSlidesButton;
- (IBAction)choseAlbum:(id)sender;
- (IBAction)exportSlides:(id)sender;
@end
