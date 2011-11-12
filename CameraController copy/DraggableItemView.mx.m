/*
     File: DraggableItemView.m 
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

#import "DraggableItemView.h"
#import "networkFunc.h"
#define TEST1
@implementation DraggableItemView
int numCamera=2;
-(NSRect) getDefaultSize{
    return defaultSize;
}
+(void)aMethod:(id)param{
    int count=-1;

    while (1) {
        usleep(100000);
        count++;
        printf("Thread %d\n",count);
        if(count%5==0) {
            [param updateCamera:count/5];
            [param setNeedsDisplayInRect:[param getDefaultSize]];
        }else if((count+1)/5==numCamera) count=-1;
    }
}
// -----------------------------------
// Initialize the View
// -----------------------------------

- (id)initWithFrame:(NSRect)frame {


    
    if (self) {
        self = [super initWithFrame:frame];
        //end of setting view size
        /*Setting socket*/
#ifndef TEST
        int i,sizeRecv;
        char buf[1024];
        float ratio;
        nF=[[networkFunc alloc]init];
        svSock=[nF initSocket:"ccx00.sfc.keio.ac.jp" :"1412"];
        printf("after connect\n");
        write(svSock, "WWWWW", 3);//send request for get camera Client IP
        sizeRecv=recv(svSock, buf, 1024, 0);
        
        memcpy(camIp, buf+sizeof(int), *(int*)(buf));
        printf("Cam IP is:%s\n",camIp);
        
        
        write(svSock, "RRRRRR", 3);//send request for get camera setting
        sizeRecv=recv(svSock, buf, 1024, 0);
        printf("size=%d\n",sizeRecv);
        if(sizeRecv<=1024){//if can recv in 1024 byte
            memcpy(&numCamera,buf+sizeof(char), sizeof(int));
            printf("have %d camera\n",numCamera);
            /*Create camera Rect*/
            for(i=0;i<numCamera;i++){
                memcpy( &ratio,buf+sizeof(char)+sizeof(int)+i*sizeof(float), sizeof(float));
                //printf("Setting camara rect %d %f:\n",i,ratio);
                //set NSIMAGE
                viewImageList[i]=NULL;
                //
                cameraPos[i].origin.x=10+i*405;
                cameraPos[i].origin.y=10;
                cameraPos[i].size.width=400;
                cameraPos[i].size.height=(int)(ratio*400);
                /*set default cameraView*/
                rotate[i]=0.0f;
                cameraView[i][0]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+10);
                cameraView[i][1]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+10);
                cameraView[i][2]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
                cameraView[i][3]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
                //end of set cameraView
            }
            activeCamera=0;
            isTmpView=false;
            /*Get try image data*/
            sockCamera= [nF initSocket:"localhost":"1413"];//camIp :"1413"];
            [NSThread detachNewThreadSelector:@selector(aMethod:) toTarget:[DraggableItemView class] withObject:self];
            //[self updateCamera:0];
            //[self updateCamera:1];
            //end of create
        }else{

        }
        //end of set socket
#endif
        
        //printf("%f %f %f %f",frame.origin.x,frame.origin.y,frame.size.height,frame.size.width);
        [super setAcceptsTouchEvents:true];
    }
    return self;
}
// -----------------------------------
// Release the View
// -----------------------------------

- (void)dealloc
{
    // release the color items and set
    // the instance variables to ni
    
    // call super
    [super dealloc];  
}


// -----------------------------------
// First Responder Methods
// -----------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

// -----------------------------------
// Handle trackpad
// -----------------------------------
/**Begin click mouse
 */

- (void)mouseDown:(NSEvent *)theEvent{
    
}
/**End click mouse
 */
- (void)mouseUp:(NSEvent *)theEvent{
    printf("b\n");
}
- (void)touchesCancelledWithEvent:(NSEvent *)event{
    printf("a\n");
}
- (void)touchesBeganWithEvent:(NSEvent *)event {
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    
    if(1||touches.count==2){//if is scroll
        printf("Begin Touch,set scroll to 0, %d, %f %f\n",touches.count,[event locationInWindow].x,[event locationInWindow].y);
        
    }
    
    sumScrollX=0;
    sumScrollY=0;
    numMoveMouse=0; //set moveMouse to 0
    maxX=0;
    minX=2;
    maxY=0;
    minY=2;
    lengthMouseMoved=0;
    radious=0.2f;
    statusMouse=0;//set status window to default

}

float xA=10,yA,xB=0,yB,xC,yC=10,xD,yD=0,xI,yI,rotate;

- (void)touchesMovedWithEvent:(NSEvent *)event{
    return;
    if(statusMouse==3) return;//dont anything
    float nowXI,nowYI,nowRadious,nowAngle;
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    if (touches.count == 2) {
        NSArray *array = [touches allObjects];
        
        NSTouch *touch,*touch2;
        float delX,delY,X,Y,delLength,len;
        touch = [array objectAtIndex:0];
        touch2 = [array objectAtIndex:1];
        
        delX=[touch normalizedPosition].x-[touch2 normalizedPosition].x;
        delY=[touch normalizedPosition].y-[touch2 normalizedPosition].y;
        X=[touch normalizedPosition].x+[touch2 normalizedPosition].x;
        Y=[touch normalizedPosition].y+[touch2 normalizedPosition].y;
        delLength=sqrtf(delX*delX+delY*delY);

        
        
//        printf("%f \n",[touch normalizedPosition].x); 
        /*Calc for detect shape of gesture*/
            //save location to array
        
        if(numMoveMouse>0)len=sqrtf((X-moveMouse[numMoveMouse-1][0])*(X-moveMouse[numMoveMouse-1][0])+(Y-moveMouse[numMoveMouse-1][1])*(Y-moveMouse[numMoveMouse-1][1]));
        else len=0;
        moveMouse[numMoveMouse][0]=X;
        moveMouse[numMoveMouse++][1]=Y;
        //set maxmin point
        /**
         A: min x, 
         B: max x
         C: min y
         D max y
         */
       
        //set maxmin X Y
        if(maxX<X) {maxX=X;maxXY=Y;}
        if(minX>X) {minX=X;minXY=Y;}
        if(maxY<Y) {maxY=Y;maxYX=X;}
        if(minY>Y) {minY=Y;minYX=X;}
        
        if(delLength<0.2){//if is for rotate (status 2)
            if(statusMouse==1) statusMouse=3;
            else{
                statusMouse=2;
                lengthMouseMoved+=len;
                xA=maxX;yA=maxXY;
                xB=minX;yB=minXY;
                if(yA==maxY||yB==maxY){//->using min
                    yC=minY;xC=minYX;
                }else if(yA!=maxY&&yB!=maxY){
                    yC=maxY;xC=maxYX;
                }else{//using diffrent point
                    return;
                }
                nowXI=(0.5f)*((xA*xA+yA*yA)*(yC-yB)+(xB*xB+yB*yB)*(yA-yC)+(xC*xC+yC*yC)*(yB-yA))/(yA*(xB- xC)+yB*(xC- xA)+yC*(xA- xB));
                nowYI=(0.5f)*((xA*xA+yA*yA)*(xB-xC)+(xB*xB+yB*yB)*(xC-xA)+(xC*xC+yC*yC)*(xA-xB))/(yA*(xB- xC)+yB*(xC- xA)+yC*(xA- xB));
                nowRadious=sqrtf((nowXI-xA)*(nowXI-xA)+(nowYI-yA)*(nowYI-yA));
                
                if(nowRadious<0.2f||isnan( nowRadious)) nowRadious=0.2f;
                radious=radious*0.8f+nowRadious*0.2f;
                nowAngle=(float)(lengthMouseMoved/((float)(pi)*radious));
                printf("Radious= nowR=%f R=%f Slen=%f ang=%f\n",nowRadious,radious,lengthMouseMoved,nowAngle*180);
                if(isTmpView==false){
                    isTmpView=true;
                    tmpRotate=rotate[activeCamera];
                    NSPoint deltaV=NSMakePoint(0,0);//(cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
                    tmpVier[0]=NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
                    tmpVier[1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
                    tmpVier[2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
                    tmpVier[3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
                    [self setNeedsDisplayInRect:defaultSize];
                }else{
                    tmpRotate+=nowAngle;//[event rotation]/180;
                    [self setNeedsDisplayInRect:defaultSize];
                    
                }
            }
        }else if(delLength>0.25){//if is for select window (status 1)
            if(statusMouse==2) statusMouse=3;
            else{
                
                statusMouse=1;
                lengthMouseMoved+=len;
                if(maxY-minY<0.1){
                    printf("Sum len=%f\n",lengthMouseMoved);
                    if(lengthMouseMoved>0.3){
                        printf("change camera\n");
                        if(moveMouse[numMoveMouse-1][0]>moveMouse[0][0])[self changeCameraX:1];
                        else [self changeCameraX:-1];
                        statusMouse=3;
                    }
                    
                }else statusMouse=3;
                    
                
            }
        }
        //printf("**%d %f %f %f %f %f\n",touches.count,delX,delY,delLength,len,lengthMouseMoved);
    }
}
- (void)touchesEndedWithEvent:(NSEvent *)event{
    //printf("End %f %f\n",[event locationInWindow].x,[event locationInWindow].y);
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    printf("Max=%f min=%f %f\n",maxY,minY,maxY-minY);
    if(touches.count==1)printf("End Touch,set scroll to 0, %d, %f %f\n",touches.count,[event locationInWindow].x,[event locationInWindow].y);
}
//
- (void)swipeWithEvent:(NSEvent *)event {
    //CGFloat x = [event deltaX];
    //CGFloat y = [event deltaY];
    //printf("Swipe %f %f\n",x,y);
}
- (void)magnifyWithEvent:(NSEvent *)event {
    //statusMouse=3;//zoom
    //printf("Zoom %f-(%f %f)\n",[event magnification],[event locationInWindow].x,[event locationInWindow].y);
    //return;
    if(isTmpView==false){
        isTmpView=true;
        tmpRotate=rotate[activeCamera];
        NSPoint deltaV=NSMakePoint((cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
        tmpVier[0]=NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
        tmpVier[1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
        tmpVier[2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
        tmpVier[3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
        [self setNeedsDisplayInRect:defaultSize];
        
        //printf("Zoom to %f %f:%f %f %f %f\n",deltaV.x,deltaV.y,tmpVier[0].x,tmpVier[0].y,tmpVier[2].x,tmpVier[2].y);
    }else{
        
        NSPoint deltaV=NSMakePoint((tmpVier[0].x+tmpVier[2].x)/2-[event locationInWindow].x, (tmpVier[0].y+tmpVier[2].y)/2-[event locationInWindow].y);
        tmpVier[0].x-=deltaV.x;
        tmpVier[0].y-=deltaV.y;
        tmpVier[1].x-=deltaV.x;
        tmpVier[1].y-=deltaV.y;
        tmpVier[2].x-=deltaV.x;
        tmpVier[2].y-=deltaV.y;
        tmpVier[3].x-=deltaV.x;
        tmpVier[3].y-=deltaV.y;
        
        NSPoint deltaV1=NSMakePoint((tmpVier[0].x-tmpVier[2].x)/2,(tmpVier[0].y-tmpVier[2].y)/2*[event magnification] );
        tmpVier[0].x+=deltaV1.x;
        tmpVier[0].y+=deltaV1.y;
        tmpVier[2].x-=deltaV1.x;
        tmpVier[2].y-=deltaV1.y;
        
        NSPoint deltaV2=NSMakePoint((tmpVier[1].x-tmpVier[3].x)/2*[event magnification],(tmpVier[1].y-tmpVier[3].y)/2*[event magnification] );
        tmpVier[1].x+=deltaV2.x;
        tmpVier[1].y+=deltaV2.y;
        tmpVier[3].x-=deltaV2.x;
        tmpVier[3].y-=deltaV2.y;
        
        [self setNeedsDisplayInRect:defaultSize];
    }
    
}

- (void)rotateWithEvent:(NSEvent *)event {
    //printf("Rotatte %f\n",[event rotation]);
    if(isTmpView==false){
        isTmpView=true;
        tmpRotate=rotate[activeCamera];
        NSPoint deltaV=NSMakePoint((cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
        tmpVier[0]=NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
        tmpVier[1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
        tmpVier[2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
        tmpVier[3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
        [self setNeedsDisplayInRect:defaultSize];
    }else{
        tmpRotate+=[event rotation]/180;
        [self setNeedsDisplayInRect:defaultSize];
        
    }
}

- (void)scrollWheel:(NSEvent *)theEvent{
    /*float nowRotate,nowXI,nowYI;
    int n,nB;
    sumScrollX+= theEvent.scrollingDeltaX;
    sumScrollY+= theEvent.scrollingDeltaY;
    if(sumScrollX>maxX) maxX=sumScrollX;
    if(sumScrollX<minX) minX=sumScrollX;
    if(sumScrollY>maxY) maxY=sumScrollY;
    if(sumScrollY<minY) minY=sumScrollY;
    lengthMouseMoved+=sqrtf(theEvent.scrollingDeltaX*theEvent.scrollingDeltaX+theEvent.scrollingDeltaY*theEvent.scrollingDeltaY);
    moveMouse[numMoveMouse][0]=sumScrollX;
    moveMouse[numMoveMouse++][1]=sumScrollY;
    //printf("Scroll:%f %f %f: %f %f\n",lengthMouseMoved,maxY,minY ,   theEvent.scrollingDeltaX,    theEvent.scrollingDeltaY);
    caculate radious*/
    /*if(numMoveMouse>20){
        xA=moveMouse[0][0];
        xA=moveMouse[0][1];
        n=numMoveMouse/2;
        xB=moveMouse[n][0];
        yB=moveMouse[n][1];
        while (n>0&&(moveMouse[0][0]-moveMouse[n][0])*(moveMouse[0][0]-moveMouse[n][0])<1000&&(moveMouse[0][1]-moveMouse[n][1])*(moveMouse[0][1]-moveMouse[n][1])<1000) {
            n--;
        }
        if(n>0){
            xB=moveMouse[n][0];
            yB=moveMouse[n][1];
            nB=n;
        }else nB=numMoveMouse/2;
        
        
        n=numMoveMouse;
        xC=moveMouse[n][0];
        yC=moveMouse[0][1];
        while (n>0&&(moveMouse[0][0]-moveMouse[n][0])*(moveMouse[0][0]-moveMouse[n][0])<1000&&(moveMouse[0][1]-moveMouse[n][1])*(moveMouse[0][1]-moveMouse[n][1])<1000&&(moveMouse[nB][0]-moveMouse[n][0])*(moveMouse[nB][0]-moveMouse[n][0])<1000&&(moveMouse[nB][1]-moveMouse[n][1])*(moveMouse[nB][1]-moveMouse[n][1])<1000) {
            n--;
        }
        if(n>0){
            xC=moveMouse[n][0];
            yC=moveMouse[n][1];
        }
        
        //caculate radious
        nowXI=(0.5f)*((xA*xA+yA*yA)*(yC-yB)+(xB*xB+yB*yB)*(yA-yC)+(xC*xC+yC*yC)*(yB-yA))/(yA*(xB- xC)+yB*(xC- xA)+yC*(xA- xB));
        nowYI=(0.5f)*((xA*xA+yA*yA)*(xB-xC)+(xB*xB+yB*yB)*(xC-xA)+(xC*xC+yC*yC)*(xA-xB))/(yA*(xB- xC)+yB*(xC- xA)+yC*(xA- xB));
        nowRotate= sqrtf(nowXI*nowXI+nowYI*nowYI);
        //printf("\n%d (%f %f) (%f %f) (%f %f)->(%f %f)--%f\n",numMoveMouse,xA,yA,xB,yB,xC,yC,nowXI,nowYI,nowRotate);
        
    }
    */
    /*if(maxY-minY<70){
       
       if(sumScrollX>300||sumScrollX<-600){
           printf("change camera\n");
           [self changeCameraX:sumScrollX];
           sumScrollX=0;
       }
    }else{
        printf("Rotate");
    }*/

}
// -----------------------------------
// Function for change camera view
// -----------------------------------
- (void)changeCameraX:(float)value{
    if(value>0){//move left
               // //printf("change camera left\n");
        
            if(activeCamera>0){
                activeCamera--;
                isTmpView=false;
                [self setNeedsDisplayInRect:defaultSize];
#ifndef TEST
                    [self sendChange:svSock];
#endif
            }
        
    }else if(value<0){//move right
              //  //printf("change camera right\n");
            if(activeCamera<numCamera-1){
                activeCamera++;
                isTmpView=false;
                [self setNeedsDisplayInRect:defaultSize];
#ifndef TEST
                [self sendChange:svSock];
#endif
            }
        
    }
  
}
// -----------------------------------
// Key listener
// -----------------------------------
float centerX,centerY,zoom;
- (void)keyDown:(NSEvent *)theEvent {
    //printf("Enter key:%d",[theEvent keyCode]);
    switch ([theEvent keyCode]) {
        case 36://enter
            if(isTmpView==true){
                isTmpView=false;
                cameraView[activeCamera][0]=tmpVier[0];
                cameraView[activeCamera][1]=tmpVier[1];
                cameraView[activeCamera][2]=tmpVier[2];                
                cameraView[activeCamera][3]=tmpVier[3];
                rotate[activeCamera]=tmpRotate;
                [self setNeedsDisplayInRect:defaultSize];
                //printf("Change cameraViewer");
#ifndef TEST
                [self sendChange:svSock];
#endif                
                printf("Rotate= %f %f\n",tmpRotate,tmpRotate/pi);
            }
            break;
        case 53:
            isTmpView=false;
            [self setNeedsDisplayInRect:defaultSize];
            break;
        default:
            break;
    }
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    
}

// -----------------------------------
// Draw the View Content
// -----------------------------------
static NSPoint tmpArr[4];
- (void)    drawCameraView:(int)idCam :(NSColor* )colorRect{
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    /*rotate Rect*/
      //move zero vector
        NSPoint center=NSMakePoint((cameraView[idCam][0].x+cameraView[idCam][2].x)/2,(cameraView[idCam][0].y+cameraView[idCam][2].y)/2);
        tmpArr[0].x=cameraView[idCam][0].x-center.x;
        tmpArr[0].y=cameraView[idCam][0].y-center.y;
        tmpArr[1].x=cameraView[idCam][1].x-center.x;
        tmpArr[1].y=cameraView[idCam][1].y-center.y;
        tmpArr[2].x=cameraView[idCam][2].x-center.x;
        tmpArr[2].y=cameraView[idCam][2].y-center.y;
        tmpArr[3].x=cameraView[idCam][3].x-center.x;
        tmpArr[3].y=cameraView[idCam][3].y-center.y;
      //rotate
        float distance,angle;
        distance=sqrtf(tmpArr[0].x*tmpArr[0].x+tmpArr[0].y*tmpArr[0].y);

        angle=atanf(tmpArr[0].y/tmpArr[0].x);
        if(tmpArr[0].x <0) angle+=(float)pi;
        tmpArr[0].x=distance*cosf(rotate[idCam]+angle);
        tmpArr[0].y=distance*sinf(rotate[idCam]+angle);
        tmpArr[2].x=distance*cosf(rotate[idCam]+angle+(float)pi);
        tmpArr[2].y=distance*sinf(rotate[idCam]+angle+(float)pi);        
        tmpArr[0].x+=center.x;
        tmpArr[0].y+=center.y;
        tmpArr[2].x+=center.x;
        tmpArr[2].y+=center.y;
    
        angle=atanf(tmpArr[1].y/tmpArr[1].x);
        if(tmpArr[1].x <0) angle+=(float)pi;
        tmpArr[1].x=distance*cosf(rotate[idCam]+angle);
        tmpArr[1].y=distance*sinf(rotate[idCam]+angle);
        tmpArr[3].x=distance*cosf(rotate[idCam]+angle+(float)pi);
        tmpArr[3].y=distance*sinf(rotate[idCam]+angle+(float)pi);        
        tmpArr[1].x+=center.x;
        tmpArr[1].y+=center.y;
        tmpArr[3].x+=center.x;
        tmpArr[3].y+=center.y;
    
    //end of rotate
    [path moveToPoint:tmpArr[0]];
    [path lineToPoint:tmpArr[1]];
    [path lineToPoint:tmpArr[2]];
    [path lineToPoint:tmpArr[3]];
    [path closePath];     
    [colorRect set];
    //[path fill];
    
    //[[NSColor blackColor] set];
    [path stroke];
}
- (void)    drawTmpCameraView{
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    /*rotate Rect*/
    //move zero vector
    NSPoint center=NSMakePoint((tmpVier[0].x+tmpVier[2].x)/2,(tmpVier[0].y+tmpVier[2].y)/2);
    tmpArr[0].x=tmpVier[0].x-center.x;
    tmpArr[0].y=tmpVier[0].y-center.y;
    tmpArr[1].x=tmpVier[1].x-center.x;
    tmpArr[1].y=tmpVier[1].y-center.y;
    tmpArr[2].x=tmpVier[2].x-center.x;
    tmpArr[2].y=tmpVier[2].y-center.y;
    tmpArr[3].x=tmpVier[3].x-center.x;
    tmpArr[3].y=tmpVier[3].y-center.y;
    //rotate
    float distance,angle;
    distance=sqrtf(tmpArr[0].x*tmpArr[0].x+tmpArr[0].y*tmpArr[0].y);
    
    angle=atanf(tmpArr[0].y/tmpArr[0].x);
    if(tmpArr[0].x <0) angle+=(float)pi;
    tmpArr[0].x=distance*cosf(tmpRotate+angle);
    tmpArr[0].y=distance*sinf(tmpRotate+angle);
    tmpArr[2].x=distance*cosf(tmpRotate+angle+(float)pi);
    tmpArr[2].y=distance*sinf(tmpRotate+angle+(float)pi);        
    tmpArr[0].x+=center.x;
    tmpArr[0].y+=center.y;
    tmpArr[2].x+=center.x;
    tmpArr[2].y+=center.y;
    
    angle=atanf(tmpArr[1].y/tmpArr[1].x);
    if(tmpArr[1].x <0) angle+=(float)pi;
    tmpArr[1].x=distance*cosf(tmpRotate+angle);
    tmpArr[1].y=distance*sinf(tmpRotate+angle);
    tmpArr[3].x=distance*cosf(tmpRotate+angle+(float)pi);
    tmpArr[3].y=distance*sinf(tmpRotate+angle+(float)pi);        
    tmpArr[1].x+=center.x;
    tmpArr[1].y+=center.y;
    tmpArr[3].x+=center.x;
    tmpArr[3].y+=center.y;
    
    //end of rotate
    [path moveToPoint:tmpArr[0]];
    [path lineToPoint:tmpArr[1]];
    [path lineToPoint:tmpArr[2]];
    [path lineToPoint:tmpArr[3]];
    [path closePath];     
    [[NSColor orangeColor] set];
    //[path fill];
    
    //[[NSColor blackColor] set];
    [path stroke];
}

- (void)drawRect:(NSRect) rectT
{
    printf("Draw\n");
    int i;
    NSPoint                 p;
    NSMutableDictionary*    attribs;
    NSColor*                c;
    NSFont*                 fnt;
    NSString*               hws;
    // erase the background by drawing white
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rectT];
    
    // set the current color for the draggable item
    [[NSColor blueColor] set];
    defaultSize=rectT;
    // draw the draggable item
    
    for(i=0;i<numCamera;i++){
        //draw image
        if(viewImageList[i]!=NULL){
            [viewImageList[i] drawAtPoint:cameraPos[i].origin];
        }
        //draw cameraViewer
        if(i!=activeCamera){
            [self drawCameraView:i :[NSColor gridColor]];
        }else{
            [self drawCameraView:i :[NSColor greenColor]];
            if(isTmpView==true)[self drawTmpCameraView];
        }
        
        //write text
        hws=[NSString stringWithFormat:@"%d", i];
    
        p = NSMakePoint( cameraPos[i].origin.x+cameraPos[i].size.width/2, cameraPos[i].origin.y+cameraPos[i].size.height/2 );
    
        attribs = [[[NSMutableDictionary alloc] init] autorelease];
    
        if(i!=activeCamera)c = [NSColor blueColor];
        else c = [NSColor redColor];
        fnt = [NSFont fontWithName:@"Times Roman" size:48];
    
        [attribs setObject:c forKey:NSForegroundColorAttributeName];
        [attribs setObject:fnt forKey:NSFontAttributeName];
    
        [hws drawAtPoint:p withAttributes:attribs];
        //draw
        [NSBezierPath strokeRect:cameraPos[i]];
        
    }
}
- (void) updateCamera:(int)numcamR{
    char imageData[370000];
    unsigned long sumRecv,sizeRecv;
    write(sockCamera, &numcamR , sizeof(int));
    //printf("sent request 0\n");
    sizeRecv=recv(sockCamera,imageData,370000,0);
    int widthImg=*((int*)imageData);
    int heightImg=*((int*)imageData+1);
    sumRecv=sizeRecv;
    while (sumRecv<widthImg*heightImg*3+sizeof(int)*2) {
        sizeRecv=recv(sockCamera,imageData+sumRecv,370000-sumRecv,0);
     sumRecv+=sizeRecv;
    }
    //printf("Recv %d %d %lu image\n",*((int*)imageData),*((int*)imageData+1),sumRecv);
    viewImageList[numcamR]=[nF convertOpenCVImage:imageData+sizeof(int)*2 :*((int*)imageData+1):*((int*)imageData) :8 :3 :*((int*)imageData)*3];
}
- (void)sendChange:(int) sock{
    centerX=(cameraView[activeCamera][1].x+cameraView[activeCamera][0].x-2*cameraPos[activeCamera].origin.x)/(2*cameraPos[activeCamera].size.width);
    centerY=(cameraView[activeCamera][1].y+cameraView[activeCamera][2].y-2*cameraPos[activeCamera].origin.y)/(2*cameraPos[activeCamera].size.height);
    zoom=(cameraView[activeCamera][1].y-cameraView[activeCamera][2].y)/(cameraPos[activeCamera].size.height);
    [nF sendData:svSock :activeCamera :centerX :centerY :rotate[activeCamera] :zoom];
}
@end
