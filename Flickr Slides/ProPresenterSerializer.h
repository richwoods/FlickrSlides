//
//  ProPresenterSerializer.h
//  Song Slide Maker
//
//  Created by Jason Terhorst on 1/2/15.
//  Copyright (c) 2015 Jason Terhorst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ProPresenterSerializer : NSObject

- (void)saveSlideOutput:(NSArray *)slides autoAdvance:(BOOL)shouldAutoAdvance toPath:(NSString *)path documentSettings:(NSDictionary *)settings;

@end
