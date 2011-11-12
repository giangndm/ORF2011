/*
     File: DraggableItemView.h
 Abstract: Part of the DraggableItemView project referenced in the 
 View Programming Guide for Cocoa documentation.
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Cocoa/Cocoa.h>
#import "networkFunc.h"
#import "fileFunc.h"
#import "linkList2.h"
#import "softmax.h"
#include <time.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
@interface DraggableItemView : NSView {
    //float moveMouse[10000][2];//using for detect mouseMove and this shape
    float preMouse[2];
    int numMoveMouse;
    float lengthMouseMoved,radious,angleG;
    float maxX,maxXY,minX,minXY,maxY,maxYX,minY,minYX;
    int statusMouse;//status mouse:0:begin, 1 is select camera, 2:rotate viewer window, 3:dont anything
    //define for sofmax
    NSBezierPath* pathGesture;
    double* arrayG;
    linkList2* gesture;
    fileFunc* gestureFile;
    double** learnData;
    double* Y;
    int numLData;
    int numID;
    Boolean isGesture;
    //Boolean isLearnning;
    
    //Boolean inScriptMode;
    //define for menu method
    IBOutlet NSTextField* statusTV;
    IBOutlet NSButton* controlBT;
    IBOutlet NSTextField* listUser;
    IBOutlet NSWindow* mainWindow;
}
- (int) getNumCamera;
-(NSRect) getDefaultSize;
+(void)aMethod:(id)param;
-(void) autogetFrameCamera;
- (id)initWithFrame:(NSRect)frame;
// -----------------------------------
//handle trackball
// -----------------------------------

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)touchesCancelledWithEvent:(NSEvent *)event;
- (void)touchesBeganWithEvent:(NSEvent *)event ;
- (void)touchesMovedWithEvent:(NSEvent *)event;
- (void)touchesEndedWithEvent:(NSEvent *)event;
- (void)swipeWithEvent:(NSEvent *)event ;
- (void)magnifyWithEvent:(NSEvent *)event;
- (void)rotateWithEvent:(NSEvent *)event;
- (void)scrollWheel:(NSEvent *)theEvent;
// -----------------------------------
// First Responder Methods
// -----------------------------------
- (BOOL)acceptsFirstResponder;
// -----------------------------------
// Draw the View Content
// -----------------------------------
- (void)drawRect:(NSRect )rectT;
- (void)    drawCameraView:(int)idCam :(NSColor* )colorRect;
- (void)    drawTmpCameraView;
- (void)    drawGestureView;
// -----------------------------------
// Function for change camera view
// -----------------------------------
- (void)applyChange;
- (void)changeCameraX:(float)value;
- (void)sendChange:(int) sock;
- (void) updateCamera:(int)idCam;
- (void) playListSave;
+ (void) threadPlayListSave:(id)param;
+ (void) threadCheckQuerryServer:(id)param;
+ (void) autoRefreshThread:(id)param;
- (void) CheckQuerryServer;
- (void) updateListView:(char*)list:(int)size;
// -----------------------------------
// Function for menu action
// ----------------------------------
- (IBAction)MNLearningNext:(id)sender;
- (IBAction)MNLearningBack:(id)sender;
- (IBAction)MNLearningPlayScript:(id)sender;
- (IBAction)MNResetCameraView:(id)sender;
- (IBAction)MNStopLearning:(id)sender;
- (IBAction)MNDefaultConfig:(id)sender;
    //------
- (IBAction)MNRemoveNext:(id)sender;
- (IBAction)MNRemoveBack:(id)sender;
- (IBAction)MNRemovePlayScript:(id)sender;
- (IBAction)MNRemoveResetCameraView:(id)sender;

-(void)getIsLearnning;
    //--------
- (IBAction)MNConnectServer:(id)sender;
- (IBAction)MNDisconnectServer:(id)sender;
//
-(long long)getTimeModifyFile:(char*)fileName;
- (IBAction)MNgetNotGetFrame:(id)sender;
//button click
- (IBAction)BTClickControlBT:(id)sender;
@end

