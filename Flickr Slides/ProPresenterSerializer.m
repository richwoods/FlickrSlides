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
	[settingsDict setObject:escapedDocumentTitle forKey:@"document_title"];
	[settingsDict setObject:[[NSUUID UUID] UUIDString] forKey:@"group_uuid"];
	
	NSMutableString * slidesString = [NSMutableString string];
	NSMutableString * cuesString = [NSMutableString string];
	NSInteger slideIndex = 0;
	for (NSDictionary * slide in slides)
	{
		NSString * uuid = [[NSUUID UUID] UUIDString];
		NSURL * fileURL = [NSURL fileURLWithPath:slide[@"filename"]];
		[slidesString appendString:[self _slideOutputForFile:[fileURL absoluteString] title:slide[@"title"] slideUUID:uuid slideIndex:slideIndex lastSlide:slideIndex == [slides count] - 1]];
		[cuesString appendString:[self _controlCueForSlideIndex:slideIndex slideUUID:uuid]];
		slideIndex++;
	}
	[settingsDict setObject:slidesString forKey:@"slides"];
	[settingsDict setObject:cuesString forKey:@"time_cues"];
	NSString * documentString = [self _documentOutputWithSettings:settingsDict];

	NSString *theZippedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"z_song_archive.zip"];
	NSString * mediaDSStorePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"media"] stringByAppendingPathComponent:@".DS_Store"];
	[[NSFileManager defaultManager] createDirectoryAtPath:[mediaDSStorePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
	NSLog(@"zip path: %@", [mediaDSStorePath stringByDeletingLastPathComponent]);



	ZipArchive * newZipFile = [[ZipArchive alloc] init];
	[newZipFile CreateZipFile2:theZippedFilePath Password:@""];

	[newZipFile addFileToZip:mediaDSStorePath newname:[documentTitle stringByAppendingPathComponent:@"media/.DS_Store"]];

	for (NSDictionary * slide in slides) {
		NSString * slideFilePath = slide[@"filename"];
		NSLog(@"path: %@", slideFilePath);
		NSURL * fileURL = [NSURL fileURLWithPath:slideFilePath];
		NSString * targetPath = [[mediaDSStorePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[fileURL absoluteString]];
		NSLog(@"target: %@", targetPath);
		NSString * targetDirectory = [targetPath stringByDeletingLastPathComponent];
		if (![[NSFileManager defaultManager] fileExistsAtPath:targetDirectory]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:targetDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		}
		[[NSFileManager defaultManager] copyItemAtPath:slideFilePath toPath:targetPath error:nil];

		NSError *attributesError = nil;
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:slideFilePath error:&attributesError];
		int fileSize = [fileAttributes fileSize];
		NSLog(@"size: %d file: %@", fileSize, slideFilePath);

		[newZipFile addFileToZip:targetPath newname:[[documentTitle stringByAppendingPathComponent:@"media"] stringByAppendingPathComponent:slideFilePath]];
	}

	NSString * xmlDocumentPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pro5", documentTitle]];

	[documentString writeToFile:xmlDocumentPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[newZipFile addFileToZip:xmlDocumentPath newname:[documentTitle stringByAppendingPathComponent:[xmlDocumentPath lastPathComponent]]];
	[newZipFile CloseZipFile2];

	[[NSFileManager defaultManager] removeItemAtPath:xmlDocumentPath error:nil];
	
	[[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:theZippedFilePath] toURL:[NSURL fileURLWithPath:path] error:nil];
}

- (NSString *)_slideOutputForFile:(NSString *)fileName title:(NSString *)title slideUUID:(NSString *)slideUUID slideIndex:(NSInteger)slideIndex lastSlide:(BOOL)lastSlide
{
	NSString * loopValue = lastSlide? @"1" : @"0";
	NSDictionary * contentProperties = @{@"slide_uuid":slideUUID, @"display_name":[[fileName lastPathComponent] stringByDeletingPathExtension], @"title":title, @"slide_index":[NSString stringWithFormat:@"%ld", (long)slideIndex], @"media_uuid":[[NSUUID UUID] UUIDString], @"filename":fileName, @"control_uuid":[[NSUUID UUID] UUIDString], @"loop_value":loopValue};
    
	NSString * documentTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"slide_element" ofType:@"slidetemplate"] encoding:NSUTF8StringEncoding error:nil];
	NSString * documentTest = [self _resultUpdatingTemplate:documentTemplate withDictionary:contentProperties];
	NSLog(@"doc: %@", documentTest);

	return documentTest;
}

- (NSString *)_controlCueForSlideIndex:(NSInteger)slideIndex slideUUID:(NSString *)uuid
{
	NSDictionary * contentProperties = @{@"slide_uuid":uuid, @"index":[NSString stringWithFormat:@"%ld", (long)slideIndex], @"uuid":[[NSUUID UUID] UUIDString]};

	NSString * documentTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cue_element" ofType:@"slidetemplate"] encoding:NSUTF8StringEncoding error:nil];
	NSString * documentTest = [self _resultUpdatingTemplate:documentTemplate withDictionary:contentProperties];
	NSLog(@"doc: %@", documentTest);

	return documentTest;
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
