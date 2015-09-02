//
//  ProPresenterSerializer.m
//  Song Slide Maker
//
//  Created by Jason Terhorst on 1/2/15.
//  Copyright (c) 2015 Jason Terhorst. All rights reserved.
//

#import "ProPresenterSerializer.h"
#import "ZipArchive.h"

#import <CoreFoundation/CoreFoundation.h>

static CGFloat kxRegularFontSize = 108.0f;

@implementation ProPresenterSerializer

- (void)saveSlideOutput:(NSArray *)slides toPath:(NSString *)path documentSettings:(NSDictionary *)settings
{
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];

	NSString * escapedDocumentTitle = (__bridge NSString *)(CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)([[path lastPathComponent] stringByDeletingPathExtension]), NULL));
	NSString * documentTitle = [[path lastPathComponent] stringByDeletingPathExtension];

	NSMutableDictionary * settingsDict = [NSMutableDictionary dictionaryWithDictionary:settings];
	[settingsDict setObject:escapedDocumentTitle forKey:@"document title"];
	
	NSMutableString * slidesString = [NSMutableString string];
	[slidesString appendString:[self _slideOutputForContent:@"" slideIndex:0]];
	NSInteger slideIndex = 1;
	for (NSString * slideText in slides)
	{
		[slidesString appendString:[self _slideOutputForContent:slideText slideIndex:slideIndex]];
		slideIndex++;
	}
	[slidesString appendString:[self _slideOutputForContent:@"" slideIndex:slideIndex]];
	[settingsDict setObject:slidesString forKey:@"slides"];
	NSString * documentString = [self _documentOutputWithSettings:settingsDict];

	NSString *theZippedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"z_song_archive.zip"];
	NSString * mediaDSStorePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"media"] stringByAppendingPathComponent:@".DS_Store"];
	[[NSFileManager defaultManager] createDirectoryAtPath:[mediaDSStorePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];

	ZipArchive * newZipFile = [[ZipArchive alloc] init];
	[newZipFile CreateZipFile2:theZippedFilePath Password:@""];

	[newZipFile addFileToZip:mediaDSStorePath newname:[documentTitle stringByAppendingPathComponent:@"media/.DS_Store"]];

	NSString * xmlDocumentPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pro5", documentTitle]];

	[documentString writeToFile:xmlDocumentPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[newZipFile addFileToZip:xmlDocumentPath newname:[documentTitle stringByAppendingPathComponent:[xmlDocumentPath lastPathComponent]]];
	[newZipFile CloseZipFile2];

	[[NSFileManager defaultManager] removeItemAtPath:xmlDocumentPath error:nil];
	
	[[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:theZippedFilePath] toURL:[NSURL fileURLWithPath:path] error:nil];
}

- (NSString *)_slideOutputForFile:(NSString *)fileName title:(NSString *)title slideIndex:(NSInteger)slideIndex
{
	
	NSDictionary * contentProperties = @{@"uuid":[[NSUUID UUID] UUIDString], @"label":title, @"index":[NSString stringWithFormat:@"%ld", (long)slideIndex]};
    
	NSString * documentTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"song_slide" ofType:@"slidetemplate"] encoding:NSUTF8StringEncoding error:nil];
	NSString * documentTest = [self _resultUpdatingTemplate:documentTemplate withDictionary:contentProperties];
	NSLog(@"doc: %@", documentTest);

	return documentTest;
}

- (NSString *)_controlCueForSlideIndex:(NSInteger)slideIndex slideUUID:(NSString *)uuid
{
    
}

- (NSString *)dataStringFromAttributedString:(NSAttributedString *)string
{
	NSData * titleDataBlob = [string RTFFromRange:NSMakeRange(0, string.length) documentAttributes:nil];
	NSString * titleData = [titleDataBlob base64EncodedStringWithOptions:0];
	return titleData;
}

- (NSString *)_resultUpdatingTemplate:(NSString *)template withDictionary:(NSDictionary *)dict
{
	NSString * resultPayload = template;
	for (NSString * key in [dict allKeys])
	{
		resultPayload = [resultPayload stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key] withString:[dict valueForKey:key]];
	}

	return resultPayload;
}

- (NSString *)_documentOutputWithSettings:(NSDictionary *)dict
{
	NSString * documentTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"document" ofType:@"slidetemplate"] encoding:NSUTF8StringEncoding error:nil];
	NSString * documentTest = [self _resultUpdatingTemplate:documentTemplate withDictionary:dict];
	return documentTest;
}

@end
