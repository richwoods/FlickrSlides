//
//  AppDelegate.m
//  Flickr Slides
//
//  Created by Jason Terhorst on 8/30/15.
//  Copyright (c) 2015 Jason Terhorst. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
	NSDictionary * _albumDictionary;
	NSDictionary * _selectedAlbumDictionary;

	dispatch_queue_t _albumQueue;
	dispatch_queue_t _photoQueue;

	NSString * _apiKey;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application

	NSDictionary * flickrKeys = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"flickr_keys" ofType:@"plist"]];
	NSAssert(flickrKeys != nil, @"Create flickr_keys.plist, and add your Flickr API keys");

	_apiKey = flickrKeys[@"key"];

	_albumQueue = dispatch_queue_create("com.flickrslides.albums", DISPATCH_QUEUE_CONCURRENT);
	_photoQueue = dispatch_queue_create("com.flickrslides.photos", DISPATCH_QUEUE_CONCURRENT);

	_albumSpinner.hidden = NO;
	[_albumSpinner startAnimation:nil];
	[self _updateAlbumsListWithCompletion:^(NSError * error) {
		_albumSpinner.hidden = YES;
		[_albumSpinner stopAnimation:nil];
		if (error) {
			[[NSAlert alertWithError:error] runModal];
		} else {
			_outputLabel.stringValue = [NSString stringWithFormat:@"%lu albums", (unsigned long)[_albumDictionary[@"photosets"][@"photoset"] count]];
			[_albumList removeAllItems];
			for (NSDictionary * photoSet in _albumDictionary[@"photosets"][@"photoset"]) {
				[_albumList addItemWithTitle:photoSet[@"title"][@"_content"]];
			}
		}
	}];
}

- (void)_updateAlbumsListWithCompletion:(void (^)(NSError * error))completion
{
	dispatch_async(_albumQueue, ^{
		NSURL * albumRequestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photosets.getList&user_id=130810352@N07&format=json&nojsoncallback=1&api_key=%@", _apiKey]];
		NSURLRequest * albumRequest = [NSURLRequest requestWithURL:albumRequestURL];
		NSError * albumRequestError = nil;
		NSURLResponse * albumResponse = nil;
		NSData * albumData = [NSURLConnection sendSynchronousRequest:albumRequest returningResponse:&albumResponse error:&albumRequestError];
		if (albumData && !albumRequestError) {
			NSError * parseError = nil;
			_albumDictionary = [NSJSONSerialization JSONObjectWithData:albumData options:NSJSONReadingAllowFragments error:&parseError];
			if (_albumDictionary) {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(nil);
				});
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(parseError);
				});
			}
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(albumRequestError);
			});
		}
	});
}

- (IBAction)choseAlbum:(id)sender;
{
	NSLog(@"album: %@", [_albumList titleOfSelectedItem]);

	NSInteger selectedAlbumIndex = [_albumList indexOfSelectedItem];
	NSDictionary * album = [_albumDictionary[@"photosets"][@"photoset"] objectAtIndex:selectedAlbumIndex];
	[self _loadPhotosForAlbum:[album[@"id"] integerValue] completion:^(NSError * error) {
		if (error) {
			[[NSAlert alertWithError:error] runModal];
		} else {
			_outputLabel.stringValue = [NSString stringWithFormat:@"%ld photos", [_selectedAlbumDictionary[@"photo"] count]];
		}
	}];
}

- (void)_loadPhotosForAlbum:(NSInteger)albumId completion:(void (^)(NSError * error))completion
{
	dispatch_async(_photoQueue, ^{
		NSURL * albumRequestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&user_id=130810352@N07&photoset_id=%ld&extras=url_o&format=json&nojsoncallback=1&api_key=%@", albumId, _apiKey]];
		NSURLRequest * albumRequest = [NSURLRequest requestWithURL:albumRequestURL];
		NSError * albumRequestError = nil;
		NSURLResponse * albumResponse = nil;
		NSData * albumData = [NSURLConnection sendSynchronousRequest:albumRequest returningResponse:&albumResponse error:&albumRequestError];
		if (albumData && !albumRequestError) {
			NSError * parseError = nil;
			NSDictionary * payloadDict = [NSJSONSerialization JSONObjectWithData:albumData options:NSJSONReadingAllowFragments error:&parseError];
			if (payloadDict) {
				_selectedAlbumDictionary = payloadDict[@"photoset"];
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(nil);
				});
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(parseError);
				});
			}
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(albumRequestError);
			});
		}
	});
}

- (IBAction)exportSlides:(id)sender;
{

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
