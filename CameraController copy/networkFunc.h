//
//  networkFunc.h
//  DragItemAround
//
//  Created by Minh Giang on 9/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>

#include <sys/types.h>  // socket(), listen(), accept(), read(), write()
#include <sys/socket.h> // socket(), listen(), accept(), read(), write()
#include <sys/uio.h>    // read(), write()

#include <netinet/in.h> // struct sockaddr_in 

#include <string.h> // memset()
#include <stdio.h>  // printf() 
#include <unistd.h> // read(), write()
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <netdb.h>

#include "linkList.h"
@interface networkFunc : NSObject{
    linkList* listSave;
   long long oldTime;
    Boolean inScriptMode;
}
-(NSBitmapImageRep*)convertOpenCVImage:(char*) d:(int)length;
-(NSBitmapImageRep*)convertOpenCVImage:(char*) d:(int)height:(int) width:(int)depth:(int)nChannels:(int)widthStep;
-(int)initSocket:(char*)name:(char*)port;
-(void)sendData:(int)sock:(char*)data;
-(void)sendData:(bool) isEndofInteract:(int)sock:(int)camNum:(float)centerRateX:(float)centerRateY :(float)rotateN:(float) zoomN;
-(char*)convertData:(char*)output:(int)camNum:(float)centerRateX:(float)centerRateY :(float)rotateN:(float) zoomN;
-(void)setScriptMode:(Boolean)tF;
-(Boolean)getScriptMode;
-(long long)getTime;
-(linkList*) getListSave;
@end
