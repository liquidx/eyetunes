/*
 
 EyeTunes.framework - Cocoa iTunes Interface
 http://www.liquidx.net/eyetunes/
 
 Copyright (c) 2005, Alastair Tse <alastair@liquidx.net>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 Neither the Alastair Tse nor the names of its contributors may
 be used to endorse or promote products derived from this software without 
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
*/


#import "EyeTunes.h"

const OSType iTunesSignature = ET_APPLE_EVENT_OBJECT_DEFAULT_APPL;

@implementation EyeTunes

+ (EyeTunes *) sharedInstance
{
	static EyeTunes *sharedObject = nil;
	if (sharedObject == nil) {
		sharedObject = [[self alloc] init];
	}
	return sharedObject;
}

#pragma mark -
#pragma mark AppleEvent Utility
#pragma mark -

- (AppleEvent *) newCommandEvent:(AEEventID)eventID
{
	OSErr err;
	AppleEvent *cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent(iTunesSignature,
							eventID,
							typeApplSignature,
							&iTunesSignature,
							sizeof(iTunesSignature),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							cmdEvent,
							NULL,
							"'----':'null'()");

	if (err != noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		return nil;
	}
	
	return cmdEvent;
}

- (void) releaseEvent:(AppleEvent *)finishedEvent
{
	AEDisposeDesc(finishedEvent);
	free(finishedEvent);
}

- (void)sendCommand:(AEEventID)commandID
{
	OSErr err;
	AppleEvent *event = [self newCommandEvent:commandID];
	err = AESendMessage(event, NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
	if (err != noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
	}
	[self releaseEvent:event];
	
}

#pragma mark -
#pragma mark iTunes Commands (No Params)
#pragma mark -


- (void)backTrack
{
	[self sendCommand:ET_BACK_TRACK];
}


- (void)fastForward
{
	[self sendCommand:ET_FAST_FORWARD];
}

- (void)nextTrack
{
	[self sendCommand:ET_NEXT_TRACK];
}

- (void)pause
{
	[self sendCommand:ET_PAUSE];
}

- (void)play
{
	[self sendCommand:ET_PLAY];
}

- (void)playPause
{
	[self sendCommand:ET_PLAYPAUSE];
}

- (void)previousTrack
{
	[self sendCommand:ET_PREVIOUS_TRACK];
}

- (void)resume
{
	[self sendCommand:ET_RESUME];
}

- (void)rewind
{
	[self sendCommand:ET_REWIND];
}

- (void)stop
{
	[self sendCommand:ET_STOP];
}

#pragma mark -
#pragma mark iTunes Properties
#pragma mark -

- (ETTrack *)currentTrack
{
	OSErr err;
	ETTrack *currentTrack = nil;
	
	/* Vars for getting reference to the current track */
	AEDesc	replyObject;
	AppleEvent getEvent, replyEvent;
	
	/* create the apple event to GET something*/
	err = AEBuildAppleEvent(kAECoreSuite,
							'getd',
							typeApplSignature,
							&iTunesSignature,
							sizeof(iTunesSignature),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							&getEvent,
							NULL,
							"'----':obj { form:prop, want:type(prop), seld:type(pTrk), from:'null'() }");
	
	if (err != noErr) {
		NSLog(@"Error creating AppleEvent: %d", err);
		return nil;
	}
	
	/* Send the Apple Event */
	err = AESendMessage(&getEvent, &replyEvent, kAEWaitReply + kAENeverInteract, kAEDefaultTimeout);
	if (err != noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
		goto cleanup_get_event;
	}

	
	/* Read Results */
	err = AEGetParamDesc(&replyEvent, keyDirectObject, typeWildCard, &replyObject);
	if (err != noErr) {
		NSLog(@"Error extracting from reply event: %d", err);
		goto cleanup_reply_event;
	}
	
	currentTrack = [[[ETTrack alloc] initWithDescriptor:&replyObject] autorelease];

cleanup_reply_event:
	AEDisposeDesc(&replyEvent);
cleanup_get_event:
	AEDisposeDesc(&getEvent);
	return currentTrack;		
}

- (ETPlaylist *)currentPlaylist
{
	OSErr err;
	ETPlaylist *currentPlaylist = nil;
	
	/* Vars for getting reference to the current track */
	AEDesc	replyObject;
	AppleEvent getEvent, replyEvent;
	
	/* create the apple event to GET something*/
	err = AEBuildAppleEvent(kAECoreSuite,
							'getd',
							typeApplSignature,
							&iTunesSignature,
							sizeof(iTunesSignature),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							&getEvent,
							NULL,
							"'----':obj { form:prop, want:type(prop), seld:type(pPla), from:'null'() }");
	
	if (err != noErr) {
		NSLog(@"Error creating AppleEvent: %d", err);
		return nil;
	}
	
	/* Send the Apple Event */
	err = AESendMessage(&getEvent, &replyEvent, kAEWaitReply + kAENeverInteract, kAEDefaultTimeout);
	if (err != noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
		goto cleanup_get_event;
	}
	
	
	/* Read Results */
	err = AEGetParamDesc(&replyEvent, keyDirectObject, typeWildCard, &replyObject);
	if (err != noErr) {
		NSLog(@"Error extracting from reply event: %d", err);
		goto cleanup_reply_event;
	}
	
	currentPlaylist = [[[ETPlaylist alloc] initWithDescriptor:&replyObject] autorelease];
	
cleanup_reply_event:
		AEDisposeDesc(&replyEvent);
cleanup_get_event:
		AEDisposeDesc(&getEvent);
	return currentPlaylist;		
}

- (ETPlaylist *)libraryPlaylist
{
	OSErr err;
	AEDesc replyObject;
	ETPlaylist *libraryPlaylist = nil;
	
	AppleEvent *replyEvent = [self getElementOfClass:ET_CLASS_LIBRARY_PLAYLIST atIndex:0];
	if (!replyEvent) {
		NSLog(@"Unable to get Library Playlist");
		return nil;
	}

	err = AEGetParamDesc(replyEvent, keyDirectObject, typeWildCard, &replyObject);
	if (err != noErr) {
		NSLog(@"Error extracting from reply event: %d", err);
		goto cleanup_reply_event;
	}
	
	libraryPlaylist = [[[ETPlaylist alloc] initWithDescriptor:&replyObject] autorelease];

cleanup_reply_event:
	AEDisposeDesc(replyEvent);
	free(replyEvent);
	return libraryPlaylist;
}

- (NSArray *)search:(ETPlaylist *)playlist forString:(NSString *)searchString inField:(DescType)typeCode
{
	OSErr err;
	AppleEvent getEvent, replyEvent;
	AEDescList replyList;
	NSString *gizmo = nil;
	NSMutableArray *trackList = nil;
		
	if (typeCode == 0) {
		gizmo = @"'----':@, pTrm:'utxt'(@)";
	}
	else {
		gizmo = [NSString stringWithFormat:@"'----':@, pTrm:'utxt'(@), pAre:%@", NSFileTypeForHFSTypeCode(typeCode)];
	}
	
	err = AEBuildAppleEvent(iTunesSignature,
							ET_SEARCH,
							typeApplSignature,
							&iTunesSignature,
							sizeof(iTunesSignature),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							&getEvent,
							NULL,
							[gizmo lossyCString],
							[playlist descriptor],
							[searchString lengthOfBytesUsingEncoding:NSUnicodeStringEncoding],
							[searchString cStringUsingEncoding:NSUnicodeStringEncoding]);
	

	if (err != noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		return nil;
	}
	
	err = AESendMessage(&getEvent, &replyEvent, kAEWaitReply + kAENeverInteract, kAEDefaultTimeout);
	if (err != noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
		goto cleanup_get_event;
	}
	
	/* Read Results */
	err = AEGetParamDesc(&replyEvent, keyDirectObject, typeAEList, &replyList);
	if (err != noErr) {
		NSLog(@"Error extracting from reply event: %d", err);
		goto cleanup_reply_event;
	}
	
	long items, i;
	err = AECountItems(&replyList, &items);
	if (err != noErr) {
		NSLog(@"Unable to access Reply List: %d", err);
		goto cleanup_reply_list;
	}
	
	trackList = [NSMutableArray arrayWithCapacity:items];
	for (i = 1; i < items + 1; i++) {
		AEDesc trackDesc;
		err = AEGetNthDesc(&replyList,
						   i,
						   typeWildCard,
						   0,
						   &trackDesc);
		if (err != noErr) {
			NSLog(@"Error rextracting from List: %d", err);
			goto cleanup_reply_list;
		}
		[trackList addObject:[[[ETTrack alloc] initWithDescriptor:&trackDesc] autorelease]];
	}

cleanup_reply_list:
	AEDisposeDesc(&replyList);
cleanup_reply_event:
		AEDisposeDesc(&replyEvent);
cleanup_get_event:
	AEDisposeDesc(&getEvent);
	
	return trackList;
	
}

@end