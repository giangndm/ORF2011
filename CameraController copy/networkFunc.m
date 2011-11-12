//
//  networkFunc.m
//  DragItemAround
//
//  Created by Minh Giang on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "networkFunc.h"
#import <Cocoa/Cocoa.h>
#define TIME_INTERVAL_SENDATA 100 //->0.1second
#define MIN_SIZE 0.1
@implementation networkFunc
+(void)scriptMethod:(id)param{
    
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        listSave=[[linkList alloc]init];
    }
    
    return self;
}
NSData* nsd;
NSBitmapImageRep* rt;
-(NSBitmapImageRep*)convertOpenCVImage:(char*) d:(int)length{
    [nsd release];
    [rt release];
    nsd= [[NSData alloc]initWithBytes:d length:length];
    rt=[[NSBitmapImageRep alloc] initWithData:nsd];
    return  rt;
}

-(NSBitmapImageRep*)convertOpenCVImage:(char*) d:(int)height:(int) width:(int)depth:(int)nChannels:(int)widthStep{
	
	
    rt= [[NSBitmapImageRep alloc]
                       initWithBitmapDataPlanes:NULL
                       pixelsWide:width 
                       pixelsHigh:height
                       bitsPerSample:8 
                       samplesPerPixel:3 
                       hasAlpha:NO 
                       isPlanar:NO 
                       colorSpaceName:@"NSCalibratedRGBColorSpace" 
                       bytesPerRow:0 
                       bitsPerPixel:0];

    int x, y;
	unsigned int colors[3];
	for(y=0; y<height; y++){
		for(x=0; x<width; x++){
            colors[2] = (unsigned int) d[(y * width*3) + (x*3)]; //  
            //x*3 due to difference between pixel coords and actual byte layout.
            colors[1] = (unsigned int) d[(y * width*3) + (x*3)+1];
            colors[0] = (unsigned int) d[(y * width*3) + (x*3)+2];

			[rt setPixel:colors atX:x y:y];
		}
	}
	
	//NSData *tif = [bmp TIFFRepresentation];
	//NSImage *im = [[NSImage alloc] initWithData:tif];
	
	return rt;
}
-(int)initSocket:(char*)name:(char*)port{
    int sk;
	struct addrinfo hints,*addr,*tmpAddr;
    struct timeval tv; /* timeval and timeout stuff*/
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    
	memset((void*)&hints,0,sizeof(hints));
	hints.ai_family=AF_UNSPEC;
	hints.ai_socktype= SOCK_STREAM;
	getaddrinfo(name,port,&hints,&addr);
    tmpAddr=addr;
    for (tmpAddr=addr; tmpAddr!=NULL; tmpAddr=tmpAddr->ai_next) {
        
        sk= socket(tmpAddr->ai_family, tmpAddr->ai_socktype, tmpAddr->ai_protocol);
        printf("Try connect with:%d\n",tmpAddr->ai_family);
        if(sk<0) continue;
        int sk_out= connect(sk, tmpAddr->ai_addr, tmpAddr->ai_addrlen);
        printf("Server connect:%d\n",sk_out);
        if(!sk_out) break;
    }
	if(tmpAddr==NULL) return  -1;
	//char buff2[1024];
	//int size;
	//size=recv(sk,buff2,1024,0);
	//buff2[size-2]='\0';
	//printf("%s\n",buff2);
    if (setsockopt(sk, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,  sizeof tv))
    {
        perror("setsockopt");
        return -1;
    }
	return sk;
}
-(void)sendData:(int)sock:(char*)data{
        write(sock, data, 4*sizeof(float)+sizeof(int)+sizeof(char));
}
float centerXPre=0.5f,centerYPre=0.5f,rotatePre=0,zoomPre=1;
int camN;
-(void)sendData:(bool) isEndofInteract:(int)sock:(int)camNum:(float)centerRateX:(float)centerRateY :(float)rotateN:(float) zoomN{
    static long long preTime=0;
    if(1||camN!=camNum||(centerXPre-centerRateX>0.1||centerXPre-centerRateX<-0.1)||(centerYPre-centerRateY>0.05||centerYPre-centerRateY<-0.1)||(rotateN-rotatePre>0.1||rotateN-rotatePre<-0.1)||(zoomN!=zoomPre||zoomN-zoomPre<-0.1)){
        
        if(isEndofInteract==true){
            printf("End of interract @@@@@@@@@@@@@@@@@@@@@\n");
        }
        if(zoomN*zoomN<MIN_SIZE*MIN_SIZE) return;
        if(isEndofInteract==false&&[self getTime]-preTime<TIME_INTERVAL_SENDATA){
            return;
        }
        preTime= [self getTime];
        printf("%f %f %f %f %f %f\n",rotateN,rotatePre,zoomPre,zoomN,centerRateX,centerRateY);
        char output[100];
        [self convertData:output:camNum:centerRateX :centerRateY :rotateN :zoomN];
        /*for scrip mode*/
        if(inScriptMode){
            [listSave insert:[self getTime]-oldTime :output:4*sizeof(float)+sizeof(int)+sizeof(char)];
            printf("inserted");
        }
        //
        printf("sent %f %f\n",centerRateX,centerRateY);
        [self sendData:sock :output];
        centerXPre=centerRateX;
        centerYPre=centerRateY;
        camN=camNum;
        rotatePre=rotateN;
        zoomPre=zoomN;
        
    }
}
-(char*)convertData:(char*)output:(int)camNum:(float)centerRateX:(float)centerRateY :(float)rotateN:(float) zoomN{
    output[0]='U';
    memcpy(output+1, &camNum, sizeof(int));
    memcpy(output+1+(sizeof(int))/sizeof(char), &centerRateX, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*1)/sizeof(char), &centerRateY, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*2)/sizeof(char), &rotateN, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*3)/sizeof(char), &zoomN, sizeof(float));
    return output;
}
-(long long)getTime{
    NSDate *start = [NSDate date];
    return  [start timeIntervalSince1970]*100;
}
-(void)setScriptMode:(Boolean)tF{
    inScriptMode=tF;
    if(tF){
        NSDate *start = [NSDate date];
        oldTime = [start timeIntervalSince1970]*100;// 1/100 second 
        printf("Begin script time %lld\n",oldTime);
        [listSave clear];
        
    }else{
        [listSave print];
        NSDate *start = [NSDate date];
        oldTime = [start timeIntervalSince1970]*100;// 1/100 second 
        printf("End script time %lld\n",oldTime);
    }
}
-(Boolean)getScriptMode{
    return inScriptMode;
}
-(linkList*) getListSave{
    return listSave;
}
@end
