/*
 File: DraggableItemView.m 
 Abstract: Control camera viewer by Trackpad
 
 Version: 1.0 
 
 Copyright (C) Spider-CPSF. 
 
 */
#import <CommonCrypto/CommonDigest.h>
#import "DraggableItemView.h"
#import "setDefaultConfigGesture.h"
#import "networkFunc.h"
#define TEST2
#define TEST3
//#define FILE_DATA_GESTURE "~/Library/Application\\ Support/SpiderDemo/softmax.txt"
//#define FILE_DATA_GESTURE_SAVE "~/Library/Application\\ Support/SpiderDemo/softmax.dat"
#define SIZE_GESTURE_VECTOR 20
#define TIME_BETWENT_2_GESTURE 300
#define MAX_ERROR_SOFTMAX 0.0000001
#define MAX_NUM_LOOP 1000
#define NUM_MAX_CLIENT 100
#define WANT_CONTROL_CAMERA "AA"//using for imcrease time strategy
#define ESCAPE_CONTROL_CAMERA "EE"//using for imcrease time strategy
#define SEND_LIST_ROUNDROBIN 'I'//using for ROUND ROBIN
#define TIME_INCREASE 2
#define ROUND_ROBIN 0
#define WEIGHT_AVG 1
#define MIN_WAIT_FRAME_TIME 3000
#define CONTROL_MOTOR 'M'
@implementation DraggableItemView
//static bool isRecvFrame=false;
static long long timeRecvFrame=0;
static int mode;//mode of strategy
static double preTimeGesture;
static float sumRotate;
static double isLearning;
static softmax* predicGesture;
static char* FILE_DATA_GESTURE;// "~/Library/Application\\ Support/SpiderDemo/softmax.txt"
static char* FILE_DATA_GESTURE_SAVE;// "~/Library/Application\\ Support/SpiderDemo/softmax.dat"
static NSRect cameraPos[10];
static int motorValue[10];
static NSRect motorPos[10];
static int activeCamera;
static NSBitmapImageRep* viewImageList[10];
static NSPoint cameraView[10][4];
static float  rotate[10];
static float tmpRotate;
static NSPoint tmpVier[4];
static bool isTmpView;
static float sumScrollX;
static float sumScrollY;
static NSRect defaultSize;
static networkFunc* nF;
static int svSock;
static int numCamera;
static int sockCamera;
static char camIp[100];
static bool isConnectServer;
static char* HOST;// "ccx00.sfc.keio.ac.jp"
static bool canSend=false;
static bool getFrame=false;
static bool isEndOfInteraction=false;
static bool isZoom=false;
static int maxHeight;

//define for show request of others users
static NSPoint listOtherCameraView[NUM_MAX_CLIENT][4];
static char listOtherCameraNickName[NUM_MAX_CLIENT*9];
static float  listOtherRotate[NUM_MAX_CLIENT];
static int  listOtherCamnum[NUM_MAX_CLIENT];
//for increase time mode
static int default_time;
static int max_time;
static float sum_time;
static float alpha_time;
static long long lastUpdate;
static bool isRequesting=false;
static char statusRequest=0;
static char* nickname="noname";
static bool isStarted=false;
static id idStarted;
//for round robin
static char listQueue[1024];
static float timeRoundRobin=10;
/** idGesture
 0-> nothing
 1-> next
 2-> back
 3-> playscript
 4-> reset camera
 
 **/
static int idGesture;
 
- (char *) pathForDataFile:(NSString*)fileName;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = @"~/Library/Application Support/SpiderDemo/";
    folder = [folder stringByExpandingTildeInPath];
    NSError* err;
    if ([fileManager fileExistsAtPath: folder] == NO)
    {
        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&err];//createDirectoryAtPath: folder attributes: nil];
        
    }
    return (char*)[folder stringByAppendingPathComponent: fileName].UTF8String;    
}

-(NSRect) getDefaultSize{
    return defaultSize;
}
static Boolean isScriptPlay;
-(Boolean) getIsScriptPlay{
    return isScriptPlay;
}
-(void) setIsScriptPlay:(Boolean)isS{
    isScriptPlay=isS;
}
+ (void) threadCheckQuerryServer:(id)param{
    [param CheckQuerryServer];
}

+ (void) threadPlayListSave:(id)param{
    if(![param getIsScriptPlay]){
        printf("Play1\n");
        [param playListSave];
    }
}
- (void) playListSave{
    int camNum;
    float width,height,cX,cY;
    float centerRateX,centerRateY,rotateN,zoomN;
    linkList* lS= [nF getListSave];
    List* tmp= [lS getList];
    long long timeC=0;
    //printf("%p\n",tmp);
    [lS print];
    //return;
    [self setIsScriptPlay:true];
    //printf("Reset draw 8:");
    [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    while(tmp!=NULL){
        printf("Play2\n");
        //printf("Restone at time:%lld\n",tmp->timeT);
        [nF sendData:svSock :tmp->value];
        /*retone cameraEffect*/
        memcpy(&camNum,tmp->value+1,  sizeof(int));
        memcpy( &centerRateX,tmp->value+1+(sizeof(int))/sizeof(char), sizeof(float));
        memcpy(&centerRateY,tmp->value+1+(sizeof(int)+sizeof(float)*1)/sizeof(char),  sizeof(float));
        memcpy( &rotateN,tmp->value+1+(sizeof(int)+sizeof(float)*2)/sizeof(char), sizeof(float));
        memcpy(&zoomN,tmp->value+1+(sizeof(int)+sizeof(float)*3)/sizeof(char),  sizeof(float));
        activeCamera=camNum;
        rotate[activeCamera]=rotateN;
        //zoom
        width=zoomN*cameraPos[activeCamera].size.width;
        height=zoomN*cameraPos[activeCamera].size.height;
        cX=centerRateX*cameraPos[activeCamera].size.width+cameraPos[activeCamera].origin.x;
        cY=centerRateY*cameraPos[activeCamera].size.height+cameraPos[activeCamera].origin.y;
        //move
        //printf("%f %f\n",cameraPos[activeCamera].origin.x,cameraPos[activeCamera].origin.y);
        cameraView[activeCamera][0]=NSMakePoint(cX+width/2,cY+height/2);
        cameraView[activeCamera][1]=NSMakePoint(cameraView[activeCamera][0].x-width, cameraView[activeCamera][0].y);
        cameraView[activeCamera][2]=NSMakePoint(cameraView[activeCamera][0].x-width, cameraView[activeCamera][0].y-height);
        cameraView[activeCamera][3]=NSMakePoint(cameraView[activeCamera][0].x, cameraView[activeCamera][0].y-height);
        [self applyChange];
        usleep((int)(tmp->timeT-timeC)*10000);
        timeC=tmp->timeT;
        tmp=tmp->next;
    }
    [self setIsScriptPlay:false];
    //printf("Reset draw 9:");
    [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    [self autogetFrameCamera];
}

- (int) getNumCamera{
    return numCamera;
}
// -----------------------------------
// Initialize the View
// -----------------------------------
- (int) getDataServer{
    int i;
    
    char buf[1024];
    char buf2[10];
    float ratio;
    svSock=[nF initSocket:HOST :"1412"];
    if(svSock<0) return svSock;
    write(svSock, "WWWWW", 3);//send request for get camera Client IP
    ssize_t sizeRecv=recv(svSock, buf, 1024, 0);
    
    memcpy(camIp, buf+sizeof(int), *(int*)(buf));
    printf("Cam IP is:%s\n",camIp);
    
    buf2[0]='R';
    memcpy(buf2+1, nickname, 8);
    write(svSock, buf2, 9);//send request for get camera setting
    sizeRecv=recv(svSock, buf, 1024, 0);
  while (1) {
    if(buf[0]!=SEND_LIST_ROUNDROBIN&&sizeRecv<=1024){//if can recv in 1024 byte
        memcpy(&numCamera,buf+sizeof(char), sizeof(int));
        
        
        //printf("have %d camera\n",numCamera);
        /*Create camera Rect*/
        maxHeight=0;
        for(i=0;i<numCamera;i++){
            memcpy( &ratio,buf+sizeof(char)+sizeof(int)+i*sizeof(float), sizeof(float));
            //printf("Setting camara rect %d %f:\n",i,ratio);
            //set NSIMAGE
            viewImageList[i]=NULL;
            //
            cameraPos[i].origin.x=10+i*405;
            cameraPos[i].origin.y=10+30;//20 is size of motor controller
            cameraPos[i].size.width=400;
            cameraPos[i].size.height=(int)(ratio*400);
            //motor post
            motorPos[i].origin.x=10+i*405;
            motorPos[i].origin.y=10;//20 is size of motor controller
            motorPos[i].size.width=400;
            motorPos[i].size.height=20;
            motorValue[i]=0;
            //end of motor post
            if(cameraPos[i].size.height>maxHeight)maxHeight=cameraPos[i].size.height;
            /*set default cameraView*/
            rotate[i]=0.0f;
            cameraView[i][0]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+10);
            cameraView[i][1]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+10);
            cameraView[i][2]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
            cameraView[i][3]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
            //end of set cameraView
            
        }
        memcpy(&mode, buf+sizeof(char)+sizeof(int)+i*sizeof(float), sizeof(int));
        NSLog(@"************* Now mode is %d ***********\n",mode);
        if(mode==TIME_INCREASE){
            memcpy(&default_time, buf+sizeof(char)+sizeof(int)*2+numCamera*sizeof(float), sizeof(int));
            memcpy(&max_time, buf+sizeof(char)+sizeof(int)*3+numCamera*sizeof(float), sizeof(int));
            memcpy(&alpha_time, buf+sizeof(char)+sizeof(int)*4+numCamera*sizeof(float), sizeof(float));
            sum_time=default_time;
            printf("Increase time mode with: defaultTime=%d , maxtime=%d, alphaTime= %f\n",default_time,max_time,alpha_time);
            lastUpdate=[nF getTime];
        }
        activeCamera=0;
        isTmpView=false;
        /*Get try image data*/
        sockCamera= [nF initSocket:camIp :"1413"];
        //[NSThread detachNewThreadSelector:@selector(aMethod:) toTarget:[DraggableItemView class] withObject:self];
        //end of create
        isConnectServer=true;
        [self needsToDrawRect:defaultSize];
        //set  size window
        NSRect oldSize= [mainWindow frame];
        
        NSLog(@"Old size:%f %f",oldSize.size.height,oldSize.size.width);
        oldSize.size.width=120+numCamera*410;
        oldSize.size.height=120+maxHeight;
        [mainWindow setFrame:oldSize display:true];

        break;
    }else{
        if(buf[0]==SEND_LIST_ROUNDROBIN&&sizeRecv<1024){
            NSLog(@"%s",buf+1+sizeof(int));
            //memcpy(listQueue, buf+1+ sizeof(int),sizeof(char)*8*(*(int*)(buf+1)));
            //[self updateListView:buf+1+ sizeof(int):8**(int*)(buf+1)];
            //listQueue[sizeof(char)*8*(*(int*)(buf+1))]='\0';
            
        }
    }
  }
    return svSock;
    //end of set socket
}
-(void) notConnectServer{
    int i;
    
    char buf[1024];
    
    float ratio;
    numCamera=3;
    //[mainWindow ];
    /*Create camera Rect*/
    for(i=0;i<numCamera;i++){
        memcpy( &ratio,buf+sizeof(char)+sizeof(int)+i*sizeof(float), sizeof(float));
        //printf("Setting camara rect %d %f:\n",i,ratio);
        //set NSIMAGE
        viewImageList[i]=NULL;
        //
        cameraPos[i].origin.x=10+i*405;
        cameraPos[i].origin.y=10+30;
        cameraPos[i].size.width=400;
        cameraPos[i].size.height=300;
        //motor pos
        motorPos[i].origin.x=10+i*405;
        motorPos[i].origin.y=10;//20 is size of motor controller
        motorPos[i].size.width=400;
        motorPos[i].size.height=20;
        //end mp
        /*set default cameraView*/
        rotate[i]=0.0f;
        cameraView[i][0]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+10);
        cameraView[i][1]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+10);
        cameraView[i][2]=NSMakePoint(cameraPos[i].origin.x+cameraPos[i].size.width-10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
        cameraView[i][3]=NSMakePoint(cameraPos[i].origin.x+10, cameraPos[i].origin.y+cameraPos[i].size.height-10);
        //end of set cameraView
    }
    maxHeight=330;//set default
    //set  size window
    NSRect oldSize= [mainWindow frame];
    
    NSLog(@"Old size:%f %f",oldSize.size.height,oldSize.size.width);
    oldSize.size.width=120+numCamera*410;
    oldSize.size.height=90+maxHeight;
    [mainWindow setFrame:oldSize display:true];

    isConnectServer=false;
    activeCamera=0;
    isTmpView=false;
    close(svSock);
    close(sockCamera);
    [self needsToDrawRect:defaultSize];
}

- (id)initWithFrame:(NSRect)frame {
    int i;
    if (self) {
        self = [super initWithFrame:frame];
        
        nF=[[networkFunc alloc]init];
        //end of setting view size
        /*Setting socket*/
        //#ifdef TEST
        [self notConnectServer];
        //[self getDataServer];   
        //#endif
        /*#ifndef TEST
         
         #endif*/
        //[nF setScriptMode:false];
        FILE_DATA_GESTURE=strdup([self pathForDataFile:@"softmax.txt"]);
        FILE_DATA_GESTURE_SAVE=strdup([self pathForDataFile:@"softmax.dat"]);
        
        pathGesture = [NSBezierPath bezierPath];
        gesture=[[linkList2 alloc]init];
        isGesture=false;
        isLearning=false;
        gestureFile=[[fileFunc alloc]init];
        [gestureFile open:FILE_DATA_GESTURE :"r+"];
        long long timeM1=[self getTimeModifyFile:FILE_DATA_GESTURE];
        long long timeM2=[self getTimeModifyFile:FILE_DATA_GESTURE_SAVE];
        if(timeM1>timeM2){
            if(learnData) free(learnData);
            learnData=NULL;
            [gestureFile readFile];
            learnData=[gestureFile getLearnData];
            Y=[gestureFile getIDarr];
            numLData=[gestureFile getNumData];
            numID=0;
            for(i=0;i<numLData;i++)if((int)Y[i]+1>numID)numID=(int)Y[i]+1;
            predicGesture=NULL;
            predicGesture=[[softmax alloc] init];
            [predicGesture softmax:numID:40];
            [predicGesture training:learnData :Y :numLData :0.0567 :MAX_ERROR_SOFTMAX:MAX_NUM_LOOP];
            [predicGesture saveMatrix:FILE_DATA_GESTURE_SAVE];
        }else{
            predicGesture=[[softmax alloc] init];
            [predicGesture softmaxLoadFile:FILE_DATA_GESTURE_SAVE];
        }
        [self setIsScriptPlay:false];
        [nF setScriptMode:false];
        [super setAcceptsTouchEvents:true];
        if(isStarted==true){
            //config listview
            [NSThread detachNewThreadSelector:@selector(aMethod:) toTarget:[DraggableItemView class] withObject:self];
            [NSThread detachNewThreadSelector:@selector(threadCheckQuerryServer:) toTarget :[DraggableItemView class] withObject:self];
        }
        [listUser setStringValue:@"aaaa"];
        [NSThread detachNewThreadSelector:@selector(autoRefreshThread:) toTarget :[DraggableItemView class] withObject:self];
    
        /*config for others users viewer*/
        for(i=0;i<NUM_MAX_CLIENT;i++) listOtherCamnum[i]=-1;
    }
    isStarted=true;
    idStarted=self;
    return self;
}
-(void) autoRefresh{
    NSString* test1;
    while (1) {
        usleep(100000);        
        test1=[NSString stringWithFormat:@"%s",listQueue];
        [listUser setStringValue:test1];
        //
        if(mode==2){
            if(statusRequest!=2){
                if(sum_time<max_time){
                    sum_time+=(float)([nF getTime]-lastUpdate)*alpha_time/100;
                    lastUpdate=[nF getTime];
                }
                if(sum_time>max_time) sum_time=max_time;
            }else{
                if(sum_time>0){
                    sum_time-=(float)([nF getTime]-lastUpdate)/100;
                    lastUpdate=[nF getTime];
                }
                if(sum_time<=0) sum_time=0;
            }
        }else if(mode==ROUND_ROBIN&&canSend==true){
            if(timeRoundRobin>0) timeRoundRobin-=(float)([nF getTime]-lastUpdate)/100;
            lastUpdate=[nF getTime];
        }
        //
        [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    }
}
+ (void) autoRefreshThread:(id)param{
    [param autoRefresh];
    
}
+(void)aMethod:(id)param{
    [param autogetFrameCamera];
}
-(void) autogetFrameCamera{
    printf("start get Frame\n");
    int count=-1;
    while (1) {
        if(!isConnectServer) {
            //printf("Reset draw 10:");
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            usleep(3000000);
            continue;
        }else{
            NSLog(@"get Frame %d\n",getFrame==true);
            if(getFrame==true){
                [self updateCamera:count/1];
            }else usleep(3000000);
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
        }
        //printf("Reset draw 11:");
        
    }
}
- (void) setSumTimeValue:(float)sumT{
    sum_time=sumT;
}
- (void) CheckQuerryServer{
    char buf[1024];
    int camNum,idClient;
    float width,height,cX,cY;
    float centerRateX,centerRateY,rotateN,zoomN;
    int sizeRecv;
    float timeTMP;
    //printf("Check at:%d\n",svSock);
    while(1){
        //sleep(1);
        //printf("Check at:%d %d\n",svSock,isConnectServer);
        if(!isConnectServer){
            sleep(1);
            continue;
        }
        //printf("Check at:%d\n",svSock);
        sizeRecv=recv(svSock, buf, 1024, 0);
        if(sizeRecv>=1){
            //printf("Recv checkQuerry %d %c\n",sizeRecv,buf[0]);
            if(buf[0]=='O'){//cant send data
                if(mode==TIME_INCREASE){
                    printf("Pre sumtime:%f ",sum_time);
                    memcpy(&timeTMP, buf+1, sizeof(float));
                    sum_time=timeTMP;
                    [self setSumTimeValue:timeTMP];
                    lastUpdate=[nF getTime];
                    printf("Set sumtim=%f\n",sum_time);
                    //[controlBT setTitle:@"Cancel"];
                    //isRequesting=true;
                    statusRequest=2;//controlling
                    
                }else if(mode==ROUND_ROBIN){
                    timeRoundRobin=*(int*)(buf+1);
                    lastUpdate=[nF getTime];
                }
                canSend=true;
                printf("Set canSend to TRUE");
                
                //[self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            }else if(buf[0]=='S'){
                if(mode==TIME_INCREASE){
                    printf("Pre sumtime:%f ",sum_time);
                    memcpy(&timeTMP, buf+1, sizeof(float));
                    [self setSumTimeValue:timeTMP];
                    lastUpdate=[nF getTime];
                    printf("Set sumtim=%f\n",sum_time);
                    //[controlBT setTitle:@"Request"];
                    //isRequesting=false;
                    statusRequest=0;//controlling
                }
                canSend=false;
                printf("Set canSend to FALSE");
                //[self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
                
            }else if(buf[0]=='F'){
                if(mode==TIME_INCREASE){
                    printf("Pre sumtime:%f ",sum_time);
                    memcpy(&timeTMP, buf+1, sizeof(float));
                    [self setSumTimeValue:timeTMP];
                    lastUpdate=[nF getTime];
                    printf("Set sumtim=%f\n",sum_time);
                    statusRequest=0;//controlling
                }
            }else if(buf[0]=='U'){//#define CAMERA_LIST_REQUEST 'R'
                memcpy(&camNum,buf+1,  sizeof(int));
                memcpy( &centerRateX,buf+1+(sizeof(int))/sizeof(char), sizeof(float));
                memcpy(&centerRateY,buf+1+(sizeof(int)+sizeof(float)*1)/sizeof(char),  sizeof(float));
                memcpy( &rotateN,buf+1+(sizeof(int)+sizeof(float)*2)/sizeof(char), sizeof(float));
                memcpy(&zoomN,buf+1+(sizeof(int)+sizeof(float)*3)/sizeof(char),  sizeof(float));
                memcpy(&idClient,buf+1+(sizeof(int)+sizeof(float)*4)/sizeof(char),  sizeof(int));
                if(camNum<0||camNum>=numCamera||centerRateX<0||centerRateX>1||centerRateY<0||centerRateY>1||zoomN==0||idClient<0||idClient>=NUM_MAX_CLIENT) continue;
                width=zoomN*cameraPos[camNum].size.width;
                height=zoomN*cameraPos[camNum].size.height;
                cX=centerRateX*cameraPos[camNum].size.width+cameraPos[camNum].origin.x;
                cY=centerRateY*cameraPos[camNum].size.height+cameraPos[camNum].origin.y;
                //
                listOtherCameraView[idClient][0]=NSMakePoint(cX+width/2,cY+height/2);
                listOtherCameraView[idClient][1]=NSMakePoint(listOtherCameraView[idClient][0].x-width, listOtherCameraView[idClient][0].y);
                listOtherCameraView[idClient][2]=NSMakePoint(listOtherCameraView[idClient][0].x-width, listOtherCameraView[idClient][0].y-height);
                listOtherCameraView[idClient][3]=NSMakePoint(listOtherCameraView[idClient][0].x, listOtherCameraView[idClient][0].y-height);
                listOtherRotate[idClient]=rotateN;
                listOtherCamnum[idClient]=camNum;
                //
                memcpy(listOtherCameraNickName+9*idClient,buf+(sizeof(char)+sizeof(int)*2+sizeof(float)*4)/sizeof(char),8);//copy nickname of client at end of buffer
                printf(" RECV from other:%d %d %f %f\n",idClient,camNum,centerRateX,centerRateY);
                //[self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            }else if(buf[0]=='N'){//new config
                int newFirstTime=*(int*)(buf+sizeof(char)+sizeof(int));
                int newMaxTime=*(int*)(buf+sizeof(char)+sizeof(int)*2);
                float newRatio=*(float*)(buf+sizeof(char)+sizeof(int)*3);
                if((*(int*)(buf+1)==TIME_INCREASE&&mode!=TIME_INCREASE)||newFirstTime!=default_time||newMaxTime!=max_time||alpha_time!=newRatio){
                    default_time=newFirstTime;
                    max_time=newMaxTime;
                    alpha_time=newRatio;
                    if(mode!=TIME_INCREASE)sum_time=default_time;
                    printf("Increase time mode with: defaultTime=%d , maxtime=%d, alphaTime= %f\n",default_time,max_time,alpha_time);
                    lastUpdate=[nF getTime];
                }
                mode=*(int*)(buf+1);
                NSLog(@"********* New mode=%d ***********",mode);
                if(mode!=TIME_INCREASE){
                    [controlBT setTransparent:true];
                }else [controlBT setTransparent:false];
                [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            }else if(buf[0]==SEND_LIST_ROUNDROBIN){
                //memcpy(listQueue, buf+1+ sizeof(int),sizeof(char)*8*(*(int*)(buf+1)));
                //listQueue[sizeof(char)*8*(*(int*)(buf+1))]='\0';
                [self updateListView:buf+1+ sizeof(int):sizeRecv-sizeof(int)-1];
                NSLog(@"*****%d %s***",*(int*)(buf+1),buf+1+sizeof(int));
                NSLog(@"Update queue roudrobin %d",sizeRecv);
                
            }
        }
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    int a;
    printf("******************");
    scanf("%d",&a);
}
-(long long)getTimeModifyFile:(char*)fileName{
    char t[100 ]="";
    struct stat b;
    if (!stat(fileName, &b)) {
        strftime(t, 100, "%d/%m/%Y %H:%M:%S", localtime( &b.st_mtime));
        printf("%s %ld\n",t,b.st_mtime);
        return b.st_mtime;
    }
    return -1;
}
// -----------------------------------
// Release the View
// -----------------------------------

- (void)dealloc
{
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
- (void)mouseDown:(NSEvent *)event{
    NSPoint deltaV=NSMakePoint((cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
    printf("clicked\n");
    if([event locationInWindow].x>=cameraPos[activeCamera].origin.x&&[event locationInWindow].x<=cameraPos[activeCamera].origin.x+cameraPos[activeCamera].size.width&&[event locationInWindow].y>=cameraPos[activeCamera].origin.y&&[event locationInWindow].y<=cameraPos[activeCamera].origin.y+cameraPos[activeCamera].size.height){
        cameraView[activeCamera][0]=NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
        cameraView[activeCamera][1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
        cameraView[activeCamera][2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
        cameraView[activeCamera][3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
        if(mode!=WEIGHT_AVG)[self applyChange];
        
    }
}

-(void)mouseDragged:(NSEvent *)event
{
    NSPoint deltaV=NSMakePoint((cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
    printf("clicked\n");
    if([event locationInWindow].x>=cameraPos[activeCamera].origin.x&&[event locationInWindow].x<=cameraPos[activeCamera].origin.x+cameraPos[activeCamera].size.width&&[event locationInWindow].y>=cameraPos[activeCamera].origin.y&&[event locationInWindow].y<=cameraPos[activeCamera].origin.y+cameraPos[activeCamera].size.height){
        cameraView[activeCamera][0]  =NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
        cameraView[activeCamera][1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
        cameraView[activeCamera][2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
        cameraView[activeCamera][3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
        if(mode!=WEIGHT_AVG)[self applyChange];
        
    }}
- (void)mouseUp:(NSEvent *)event{
    if(mode!=WEIGHT_AVG) return;
    NSPoint deltaV=NSMakePoint((cameraView[activeCamera][0].x+cameraView[activeCamera][2].x)/2-[event locationInWindow].x, (cameraView[activeCamera][0].y+cameraView[activeCamera][2].y)/2-[event locationInWindow].y);
    printf("clicked\n");
    if([event locationInWindow].x>=cameraPos[activeCamera].origin.x&&[event locationInWindow].x<=cameraPos[activeCamera].origin.x+cameraPos[activeCamera].size.width&&[event locationInWindow].y>=cameraPos[activeCamera].origin.y&&[event locationInWindow].y<=cameraPos[activeCamera].origin.y+cameraPos[activeCamera].size.height){
        cameraView[activeCamera][0]=NSMakePoint(cameraView[activeCamera][0].x-deltaV.x,cameraView[activeCamera][0].y-deltaV.y);
        cameraView[activeCamera][1]=NSMakePoint(cameraView[activeCamera][1].x-deltaV.x,cameraView[activeCamera][1].y-deltaV.y);
        cameraView[activeCamera][2]=NSMakePoint(cameraView[activeCamera][2].x-deltaV.x,cameraView[activeCamera][2].y-deltaV.y);
        cameraView[activeCamera][3]=NSMakePoint(cameraView[activeCamera][3].x-deltaV.x,cameraView[activeCamera][3].y-deltaV.y);
        [self applyChange];
        
    }
}
- (void)touchesCancelledWithEvent:(NSEvent *)event{
    
}
float xA=10,yA,xB=0,yB,xC,yC=10,xD,yD=0,xI,yI,rotate1;
float maxDelLeng=0,minDelLeng=2,delLength;
int multi;
- (void)touchesMovedWithEvent:(NSEvent *)event{
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    if(touches.count==2){
        
        NSArray *array = [touches allObjects];
        NSTouch *touch,*touch2;
        touch = [array objectAtIndex:0];
        touch2 = [array objectAtIndex:1];
        
        /*insert to list point for gesture*/
        if(isGesture==true){
            [gesture  insert:[touch normalizedPosition].x+[touch2 normalizedPosition].x
                            :[touch normalizedPosition].y+[touch2 normalizedPosition].y];
        }
        //
    }
}
/** idGesture
 0-> nothing
 1-> next
 2-> back
 3-> playscript
 4-> reset camera
 
 **/
- (void)doSomething:(int) ID{
    switch (ID) {
        case 0:
            break;
        case 4:
            printf("Reset cameraviewer\n");
            //set default cameraView/
            rotate[activeCamera]=0.0f;
            cameraView[activeCamera][0]=NSMakePoint(cameraPos[activeCamera].origin.x+10, cameraPos[activeCamera].origin.y+10);
            cameraView[activeCamera][1]=NSMakePoint(cameraPos[activeCamera].origin.x+cameraPos[activeCamera].size.width-10, cameraPos[activeCamera].origin.y+10);
            cameraView[activeCamera][2]=NSMakePoint(cameraPos[activeCamera].origin.x+cameraPos[activeCamera].size.width-10, cameraPos[activeCamera].origin.y+cameraPos[activeCamera].size.height-10);
            cameraView[activeCamera][3]=NSMakePoint(cameraPos[activeCamera].origin.x+10, cameraPos[activeCamera].origin.y+cameraPos[activeCamera].size.height-10);
            [self applyChange];
            //end of set cameraView
            break;
        case 1:
            [self changeCameraX:-1];
            break;
        case 2:
            [self changeCameraX:1];
            break;
        case 5://record script
            printf("Script mode\n");
            [nF setScriptMode:![nF getScriptMode]];
            [statusTV setStringValue:@"Recording script......."];
            if([nF getScriptMode]){
                printf("%p\n",statusTV);
                [statusTV setStringValue:@"Recording script......."];
            }
            //printf("Reset draw 1:");
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            break;
        case 6:
            isLearning=!isLearning;
            if(isLearning){
                [gestureFile open:FILE_DATA_GESTURE :"a+"];
            }else{
                [gestureFile reload];
                //[gestureFile open:FILE_DATA_GESTURE :"r+"];
                //reset Softmax
            }
            //printf("Reset draw 2:");
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
            break;
        case 3://play script
            printf("Playing\n");
            [statusTV setStringValue:@"Playing script......."];
            [NSThread detachNewThreadSelector:@selector(threadPlayListSave:) toTarget:[DraggableItemView class] withObject:self];
            break;
        default:
            break;
    }
}
- (void)touchesEndedWithEvent:(NSEvent *)event{
    isEndOfInteraction=true;
    printf("End of interact-first step\n");
    if(mode==1){//if is weight mode
        if(isZoom){
            [self applyChange];
            isZoom=false;
        }
        
    }
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    if(touches.count==2){
        NSArray *array = [touches allObjects];
        NSTouch *touch,*touch2;
        touch = [array objectAtIndex:0];
        touch2 = [array objectAtIndex:1];
        //printf("%f %f %f %f\n",[touch normalizedPosition].x,[touch normalizedPosition].y,[touch2 normalizedPosition].x,[touch2 normalizedPosition].y);
    }
    /*set gesture begin*/
    if(isGesture==true){
        
        //[gesture print];
        printf("Length=%d\n",[gesture getSize]);
        /*copy data to array*/
        if(isLearning){
            [gestureFile write:idGesture :[gesture getNomalArray:SIZE_GESTURE_VECTOR]:SIZE_GESTURE_VECTOR*2];
        }else if([gesture getSize]>9){
            
            double tyle;
            arrayG=[gesture getNomalArray:SIZE_GESTURE_VECTOR];
            if(arrayG){
                int idG=[predicGesture test: arrayG :&tyle];
                printf("Gesture %d %lf\n",idG,tyle);
                if(tyle>0.6)[self doSomething:idG];
                preTimeGesture=[[NSDate date] timeIntervalSince1970]*1000;
                //printf("Reset draw 3:");
                [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
                //[self drawGestureView:arrayG];
            }
        }else{
            preTimeGesture=[[NSDate date] timeIntervalSince1970]*1000;
        }
        //
        isGesture=false;
        [gesture clear];
    }
    //
}
- (void)touchesBeganWithEvent:(NSEvent *)event {
    isEndOfInteraction=false;
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    float delX,delY;
    printf("Touch %u\n",touches.count);
    sumRotate=0;//define for change speed rotate
    if(touches.count==2){//if is scroll
        printf("Begin Touch,set scroll to 0, %d, %f %f\n",touches.count,[event locationInWindow].x,[event locationInWindow].y);
        NSArray *array = [touches allObjects];
        NSTouch *touch,*touch2;
        touch = [array objectAtIndex:0];
        touch2 = [array objectAtIndex:1];
        preMouse[0]=[touch normalizedPosition].x+[touch2 normalizedPosition].x;
        preMouse[1]=[touch normalizedPosition].y+[touch2 normalizedPosition].y;
        delX=[touch normalizedPosition].x-[touch2 normalizedPosition].x;
        delY=[touch normalizedPosition].y-[touch2 normalizedPosition].y;
        delLength=sqrtf(delX*delX+delY*delY);
        /*set gesture begin*/
        printf("%f %f\n",[[NSDate date] timeIntervalSince1970],preTimeGesture);
        if([[NSDate date] timeIntervalSince1970]*1000-preTimeGesture>TIME_BETWENT_2_GESTURE){
            isGesture=true;
            [gesture clear];
        }
        //
    }else if(touches.count==4){
        [self doSomething:5];//start record script
    }
    
    sumScrollX=0;
    sumScrollY=0;
    numMoveMouse=1; //set moveMouse to 1
    maxX=0;
    minX=2;
    maxY=0;
    minY=2;
    xI=1;
    yI=1;
    lengthMouseMoved=0;
    radious=0.3f;
    angleG=0;
    statusMouse=0;//set status window to default
    maxDelLeng=0;minDelLeng=2;
}
////////////////////////////
//DO some thing with gesture ID
////////////////////////////
- (void)swipeWithEvent:(NSEvent *)event {
}
- (void)magnifyWithEvent:(NSEvent *)event {
    isGesture=false;
    NSPoint deltaV1=NSMakePoint((cameraView[activeCamera][0].x-cameraView[activeCamera][2].x)/2*[event magnification],(cameraView[activeCamera][0].y-cameraView[activeCamera][2].y)/2*[event magnification] );
    cameraView[activeCamera][0].x+=deltaV1.x;
    cameraView[activeCamera][0].y+=deltaV1.y;
    cameraView[activeCamera][2].x-=deltaV1.x;
    cameraView[activeCamera][2].y-=deltaV1.y;
    
    NSPoint deltaV2=NSMakePoint((cameraView[activeCamera][1].x-cameraView[activeCamera][3].x)/2*[event magnification],(cameraView[activeCamera][1].y-cameraView[activeCamera][3].y)/2*[event magnification] );
    cameraView[activeCamera][1].x+=deltaV2.x;
    cameraView[activeCamera][1].y+=deltaV2.y;
    cameraView[activeCamera][3].x-=deltaV2.x;
    cameraView[activeCamera][3].y-=deltaV2.y;
    if(mode!=1)[self applyChange];
    else{
        isZoom=true;
        [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    }
    
    
}

- (void)rotateWithEvent:(NSEvent *)event {
    isGesture=false;
    //printf("Rotatte %f\n",[event rotation]);
    //statusMouse=3;
    //return
    sumRotate+=[event rotation];
    rotate[activeCamera]+=[event rotation]/180*5*(1+ (sumRotate>0?sumRotate:-1*sumRotate)/20);
    if(mode!=1)[self applyChange];//if is weight mode -> check for not send much request
    else{
        isZoom=true;
        [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    }
    
}
- (void)scrollWheel:(NSEvent *)theEvent{
    //printf("Scroll:sum %f %f: %f %f\n",sumScrollX,sumScrollY ,   theEvent.scrollingDeltaX,    theEvent.scrollingDeltaY);
    return;
}
- (void)changeCameraX:(float)value{
    if(value>0){//move left
        // //printf("change camera left\n");
        
        if(activeCamera>0){
            activeCamera--;
            isTmpView=false;
            [self applyChange];
        }
        
    }else if(value<0){//move right
        //  //printf("change camera right\n");
        if(activeCamera<numCamera-1){
            activeCamera++;
            isTmpView=false;
            [self applyChange];
        }
        
    }
    
}
- (void)applyChange{
    [self setNeedsDisplay:true];
    [self sendChange:svSock];
}
- (void) setCameraEffect:(char*)data{
    
}
// -----------------------------------
// Key listener
// -----------------------------------
float centerX,centerY,zoom;
- (void)keyDown:(NSEvent *)theEvent {
    char buf[128];
    switch ([theEvent keyCode]) {
        case 123:
            buf[0]=CONTROL_MOTOR;
            motorValue[activeCamera]-=5;
            if(motorValue[activeCamera]<-50) motorValue[activeCamera]=-50;
            *(int*)(buf+1)= activeCamera;
            *(int*)(buf+1+sizeof(int))= motorValue[activeCamera];
            
            NSLog(@"Send control motor:%d %d",activeCamera,motorValue[activeCamera]);
            write(svSock, buf, sizeof(int)*2+1);
            return;
            break;
        case 124:
            buf[0]=CONTROL_MOTOR;
            motorValue[activeCamera]+=5;
            if(motorValue[activeCamera]>50) motorValue[activeCamera]=50;
            *(int*)(buf+1)= activeCamera;
            *(int*)(buf+1+sizeof(int))= motorValue[activeCamera];
            NSLog(@"Send control motor:%d %d",activeCamera,motorValue[activeCamera]);
            write(svSock, buf, sizeof(int)*2+1);
            return;
            break;
    }
    printf("Enter key:%d",[theEvent keyCode]);
    if(isLearning)if([theEvent keyCode]>=82&&[theEvent keyCode]<=92){
        idGesture=[theEvent keyCode]-82;
        printf("now ID is:%d\n",idGesture);
        //printf("Reset draw 4:");
        [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    }
    if(isLearning){
        idGesture=[theEvent keyCode]-17;
        switch ([theEvent keyCode]) {
            case 29:
                idGesture=0;
                break;
            case 18:
                idGesture=1;
                break;
            case 19:
                idGesture=2;
                break;
            case 20:
                idGesture=3;
                break;
            case 21:
                idGesture=4;
                break;
            case 23:
                idGesture=5;
                break;
            case 22:
                idGesture=6;
                break;
            case 26:
                idGesture=7;
                break;
            case 28:
                idGesture=8;
                break;
            case 25:
                idGesture=9;
                break;
            
            default:
                break;
        }
        printf("now ID is:%d\n",idGesture);
        //printf("Reset draw 5:");
        [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
    }
    switch ([theEvent keyCode]) {
        case 37://"L
            break;
        case 35://P-> play script
            //[self playListSave];
            [self doSomething:3];
            break;
        case 36://enter
            break;
        default:
            break;
    }
    
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    
}

// -----------------------------------
// Draw the View Content
// -----------------------------------
- (void) updateListView:(char*)list:(int)size{
    //char tmpList[strlen(list)/8*9];
    int i;
    for(i=0;i< (int)size/8;i++){
        printf("%d %d %d %d %c\n",i,i*9,i*9+8,i*8,list[i*8]);
        memcpy(listQueue+i*9,list+i*8,8);
        listQueue[i*9+8]='\n';
    }
    listQueue[(int)size/8*9]='\0';
    printf("**%s**\n",listQueue);
    NSString* test1=[NSString stringWithFormat:@"%s",listQueue];
    [listUser setStringValue:test1];
}
static NSPoint tmpArr[4];
- (void)drawSetRecordMode:(Boolean)isIn{
    NSBezierPath* path = [NSBezierPath bezierPath];
    tmpArr[0].x=20;
    tmpArr[0].y=maxHeight+10;
    tmpArr[1].x=20;
    tmpArr[1].y=maxHeight+30;
    tmpArr[2].x=40;
    tmpArr[2].y=maxHeight+30;
    tmpArr[3].x=40;
    tmpArr[3].y=maxHeight+10;
    [path moveToPoint:tmpArr[0]];
    [path lineToPoint:tmpArr[1]];
    [path lineToPoint:tmpArr[2]];
    [path lineToPoint:tmpArr[3]];
    [path closePath];     
    if(isIn)[[NSColor redColor] set];
    else [[NSColor shadowColor] set];;
    [path fill];
}
- (void)drawPlayRecordMode:(Boolean)isIn{
    NSBezierPath* path = [NSBezierPath bezierPath];
    tmpArr[0].x=50;
    tmpArr[0].y=maxHeight+10;
    tmpArr[1].x=50;
    tmpArr[1].y=maxHeight+30;
    tmpArr[2].x=70;
    tmpArr[2].y=maxHeight+20;
    [path moveToPoint:tmpArr[0]];
    [path lineToPoint:tmpArr[1]];
    [path lineToPoint:tmpArr[2]];
    [path closePath];     
    if(isIn)[[NSColor redColor] set];
    else [[NSColor shadowColor] set];;
    [path fill];
}
- (void)drawTimeIncreaseTimeMode:(float)sum_time2{
    NSBezierPath* path = [NSBezierPath bezierPath];
    tmpArr[0].x=50;
    tmpArr[0].y=maxHeight+40;
    tmpArr[1].x=50;
    tmpArr[1].y=maxHeight+50;
    tmpArr[2].x=(int)(sum_time2/max_time*100)+50;
    tmpArr[2].y=maxHeight+40;
    tmpArr[3].x=(int)(sum_time2/max_time*100)+50;
    tmpArr[3].y=maxHeight+50;
    [path moveToPoint:tmpArr[0]];
    [path lineToPoint:tmpArr[1]];
    [path lineToPoint:tmpArr[3]];
    [path lineToPoint:tmpArr[2]];
    [path closePath];     
    [[NSColor redColor] set];
    [path fill];
}
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

- (void)    drawGestureView{
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
- (void)    drawListOtherCameraView:(int)idClient{
    NSMutableDictionary*    attribs;
    NSColor*                c;
    NSFont*                 fnt;
    NSString*               hws;
    NSBezierPath* path = [NSBezierPath bezierPath];
    /*rotate Rect*/
    //move zero vector
    NSPoint center=NSMakePoint((listOtherCameraView[idClient][0].x+listOtherCameraView[idClient][2].x)/2,(listOtherCameraView[idClient][0].y+listOtherCameraView[idClient][2].y)/2);
    tmpArr[0].x=listOtherCameraView[idClient][0].x-center.x;
    tmpArr[0].y=listOtherCameraView[idClient][0].y-center.y;
    tmpArr[1].x=listOtherCameraView[idClient][1].x-center.x;
    tmpArr[1].y=listOtherCameraView[idClient][1].y-center.y;
    tmpArr[2].x=listOtherCameraView[idClient][2].x-center.x;
    tmpArr[2].y=listOtherCameraView[idClient][2].y-center.y;
    tmpArr[3].x=listOtherCameraView[idClient][3].x-center.x;
    tmpArr[3].y=listOtherCameraView[idClient][3].y-center.y;
    //rotate
    float distance,angle;
    distance=sqrtf(tmpArr[0].x*tmpArr[0].x+tmpArr[0].y*tmpArr[0].y);
    
    angle=atanf(tmpArr[0].y/tmpArr[0].x);
    if(tmpArr[0].x <0) angle+=(float)pi;
    tmpArr[0].x=distance*cosf(listOtherRotate[idClient]+angle);
    tmpArr[0].y=distance*sinf(listOtherRotate[idClient]+angle);
    tmpArr[2].x=distance*cosf(listOtherRotate[idClient]+angle+(float)pi);
    tmpArr[2].y=distance*sinf(listOtherRotate[idClient]+angle+(float)pi);        
    tmpArr[0].x+=center.x;
    tmpArr[0].y+=center.y;
    tmpArr[2].x+=center.x;
    tmpArr[2].y+=center.y;
    
    angle=atanf(tmpArr[1].y/tmpArr[1].x);
    if(tmpArr[1].x <0) angle+=(float)pi;
    tmpArr[1].x=distance*cosf(listOtherRotate[idClient]+angle);
    tmpArr[1].y=distance*sinf(listOtherRotate[idClient]+angle);
    tmpArr[3].x=distance*cosf(listOtherRotate[idClient]+angle+(float)pi);
    tmpArr[3].y=distance*sinf(listOtherRotate[idClient]+angle+(float)pi);        
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
    [[NSColor grayColor] set];
    //[path fill];
    
    //[[NSColor blackColor] set];
    [path stroke];
    
    //write nickname
    *((char*)listOtherCameraNickName+9*idClient+8)='\0';
    //write text
    hws=[NSString stringWithFormat:@"%s", ((char*)listOtherCameraNickName+9*idClient)];
    attribs = [[[NSMutableDictionary alloc] init] autorelease];
    c = [NSColor redColor];
    fnt = [NSFont fontWithName:@"Times Roman" size:10];
    [attribs setObject:c forKey:NSForegroundColorAttributeName];
    [attribs setObject:fnt forKey:NSFontAttributeName];
    [hws drawAtPoint:tmpArr[0] withAttributes:attribs];
}
- (void)drawRect:(NSRect) rectT
{
    //printf("Reset draw %d %f %f\n",statusRequest,rectT.size.width,rectT.origin.x);
    NSRect tmp;
    int i;
    NSPoint                 p;
    NSMutableDictionary*    attribs;
    NSColor*                c;
    NSFont*                 fnt;
    NSString*               hws;
    // erase the background by drawing white
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rectT];
    //draw isRecord mode?
    [self drawSetRecordMode:[nF getScriptMode]];
    [self drawPlayRecordMode:[self getIsScriptPlay]];
    
    // set the current color for the draggable item
    [[NSColor blueColor] set];
    defaultSize=rectT;
    
    // draw the gesture line
    if(isGesture) [self drawGestureView];
    //draw status if you can or can't send data
    if(isConnectServer){
        switch (mode) {
            case ROUND_ROBIN://0 -> roundRobin
                if(canSend)hws=[NSString stringWithFormat:@"ラウンドロビンモード：レディー %.1f",timeRoundRobin];
                else hws=[NSString stringWithFormat:@"ラウンドロビンモード：ちょっと待って.."];
                break;
            case WEIGHT_AVG://    -> weighted vector
                hws=[NSString stringWithFormat:@"重み付けモード"];
                break;
            case TIME_INCREASE:// -> increase time
                [self drawTimeIncreaseTimeMode:sum_time];
                if(statusRequest==2)hws=[NSString stringWithFormat:@"予約モード:コントロールしている:%.1f",sum_time];
                else if(statusRequest==1)hws=[NSString stringWithFormat:@"予約モード:ちょっと待っている:%.1f",sum_time];
                else hws=[NSString stringWithFormat:@"予約モード:%.1f",sum_time];
                printf("%f %s\n",sum_time,hws.UTF8String);
                break;
            default:
                break;
        }
        
        p = NSMakePoint( 100, maxHeight+10 );
        
        attribs = [[[NSMutableDictionary alloc] init] autorelease];
        
        if(canSend)c = [NSColor blueColor];
        else c = [NSColor redColor];
        fnt = [NSFont fontWithName:@"Times Roman" size:20];
        
        [attribs setObject:c forKey:NSForegroundColorAttributeName];
        [attribs setObject:fnt forKey:NSFontAttributeName];
        
        [hws drawAtPoint:p withAttributes:attribs];
    }
    //
    for(i=0;i<numCamera;i++){
        //draw image
        if(viewImageList[i]!=NULL){
            [viewImageList[i] drawAtPoint:cameraPos[i].origin];
        }
        //draw cameraViewer
        if(i!=activeCamera){
            [self drawCameraView:i :[NSColor orangeColor]];
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
        //draw motor controller
        [NSBezierPath strokeRect:motorPos[i]];
            //draw value of motor
            tmp.size.height=20;
            tmp.size.width=6;
            tmp.origin.x=motorPos[i].origin.x+motorPos[i].size.width*(1.0/2+motorValue[i]/100.0)-3;
            tmp.origin.y=10;
            [NSBezierPath strokeRect:tmp];
        
    }
    //draw others users viewer
    for(i=0;i<NUM_MAX_CLIENT;i++)if(listOtherCamnum[i]>=0){
        [self drawListOtherCameraView:i];
    }
}
void calculate_md5_of(const void *content, ssize_t len,unsigned char* md_value){
    int i;
    CC_MD5(content, len, md_value);
    printf("MD5:");
    for(i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        printf ("%02x", md_value[i]);
    }
    printf("\n");
    
    
}
- (bool)compareMD5:(char*) test1:(char*) test2:(int) size{
    int i;
    for(i=0;i<size;i++){
        if(test1[i]!=test2[i]) return false;
    }
    return true;
}
- (void) updateCamera:(int)numcamR{
    unsigned char md_value[CC_MD5_DIGEST_LENGTH];
    timeRecvFrame=[nF getTime];
    char imageData[370000];
    unsigned long sizeRecv;
    //write(sockCamera, &numcamR , sizeof(int));
    NSLog(@"Wait frame\n");
    sizeRecv=recv(sockCamera,imageData,370000,0);
    printf("recv:%ld\n",sizeRecv);
    if(sizeRecv<=0){
        printf("Disconnect from camera\n");
        getFrame=false;
        return;
    }
    memcpy(&numcamR, imageData+CC_MD5_DIGEST_LENGTH, sizeof(int));
    int sumSize=numcamR/10;
    int sumRecv= sizeRecv-sizeof(int)-CC_MD5_DIGEST_LENGTH;
    numcamR=numcamR%10;
    printf("Sumsize=%d\n",sumSize);
    if(sumSize<=0||sumSize>30000||numcamR>=numCamera||numcamR<0){
        NSLog(@"Invail data form");
        return;//check false
    }
    
    while(sumSize>sumRecv&&[nF getTime]-timeRecvFrame< MIN_WAIT_FRAME_TIME){
        sizeRecv=recv(sockCamera,imageData+CC_MD5_DIGEST_LENGTH+sumRecv+sizeof(int),370000-sumRecv-sizeof(int),0);
        if(sizeRecv<=0){
            printf("Sock closed\n");
            getFrame=false;
            return;
        }
        /*if(sizeRecv==(unsigned long)-1){
            printf("Timeout->Exit\n");
            return;
        }*/
        sumRecv+=sizeRecv;
        printf("%d %d %ld\n",sumRecv,sumSize,sizeRecv);
    }
    if(sumSize!=sumRecv){
        printf("Diffrent size\n");
    //    return;
    }
    calculate_md5_of(imageData+CC_MD5_DIGEST_LENGTH, sumSize+sizeof(int), md_value);
    //
    if(![self compareMD5:(char*)md_value :imageData :CC_MD5_DIGEST_LENGTH]){
        printf("False MD5\n");
        return;
    }else printf("True MD5\n");
    //
    if([nF getTime]-timeRecvFrame<= MIN_WAIT_FRAME_TIME){
        viewImageList[numcamR]=[nF convertOpenCVImage:imageData+sizeof(int)+CC_MD5_DIGEST_LENGTH:sumSize];
        printf("Update viewer %d\n",sumSize);
    }else printf("Update frame timeout");

}
- (void)sendChange:(int) sock{
    //printf("Send change %f %f\n",(cameraView[activeCamera][2].x+cameraView[activeCamera][0].x)/2,(cameraView[activeCamera][2].y+cameraView[activeCamera][0].y)/2);
    //printf("(%f %f)(%f %f)(%f %f)(%f %f)",cameraView[activeCamera][0].x,cameraView[activeCamera][0].y,cameraView[activeCamera][1].x,cameraView[activeCamera][1].y,cameraView[activeCamera][2].x,cameraView[activeCamera][2].y,cameraView[activeCamera][3].x,cameraView[activeCamera][3].y);
    centerX=(cameraView[activeCamera][1].x+cameraView[activeCamera][0].x-2*cameraPos[activeCamera].origin.x)/(2*cameraPos[activeCamera].size.width);
    centerY=(cameraView[activeCamera][1].y+cameraView[activeCamera][2].y-2*cameraPos[activeCamera].origin.y)/(2*cameraPos[activeCamera].size.height);
    zoom=(cameraView[activeCamera][1].y-cameraView[activeCamera][2].y)/(cameraPos[activeCamera].size.height);
    printf("End of interacti=%d\n",isEndOfInteraction==true);
    if(mode==1)[nF sendData:isEndOfInteraction:svSock :activeCamera :centerX :centerY :rotate[activeCamera] :zoom];
    else [nF sendData:true:svSock :activeCamera :centerX :centerY :rotate[activeCamera] :zoom];
}
// -----------------------------------
// Function for menu action
// ----------------------------------
// -----------------------------------
// Function for menu action
// ----------------------------------
- (IBAction)MNLearningNext:(id)sender{
    [statusTV setStringValue:@"Learning Next Gesture"];
    isLearning=true;
    idGesture=1;
    
}
- (IBAction)MNLearningBack:(id)sender{
    [statusTV setStringValue:@"Learning Back Gesture"];    
    isLearning=true;
    idGesture=2;
}
- (IBAction)MNLearningPlayScript:(id)sender{
    [statusTV setStringValue:@"Learning Play Script Gesture"];
    isLearning=true;
    idGesture=3;
}
- (IBAction)MNResetCameraView:(id)sender{
    [statusTV setStringValue:@"Learning Reset Camera View Gesture"];
    isLearning=true;
    idGesture=4;
}
- (char*) getFileDataSave{
    return strdup(FILE_DATA_GESTURE_SAVE);
}
- (char*) getFileData{
    return strdup(FILE_DATA_GESTURE);
}
- (void) reloadDATA{
    int i;
    isLearning=false;
    idGesture=0;    
    //reload data
    printf("FIle save:%s--%s\n",[self getFileData], [self getFileDataSave]);
    fileFunc* gestureFile1=[[fileFunc alloc]init];
    [gestureFile1 open:[self getFileData] :"r+"];
    {
        [gestureFile1 readFile];
        learnData=[gestureFile1 getLearnData];
        Y=[gestureFile1 getIDarr];
        numLData=[gestureFile1 getNumData];
        numID=0;
        for(i=0;i<numLData;i++)if((int)Y[i]+1>numID)numID=(int)Y[i]+1;
        [predicGesture dealloc];
        predicGesture=[[softmax alloc] init];
        [predicGesture softmax:numID:40];
        [predicGesture training:learnData :Y :numLData :0.0567 :MAX_ERROR_SOFTMAX:MAX_NUM_LOOP];
        [predicGesture saveMatrix:FILE_DATA_GESTURE_SAVE];
    }
}
- (IBAction)MNStopLearning:(id)sender{
    
    [statusTV setStringValue:@"Reloading All Gesture Data...."];
    [self reloadDATA];
    [statusTV setStringValue:@"Reloaded All Gesture Data"];
}
- (IBAction)MNDefaultConfig:(id)sender{
    setDefaultConfigGesture* sDCG=[[setDefaultConfigGesture alloc]init];
    [sDCG writeDefaultConfig:[self pathForDataFile:@"softmax.txt"]];
    [sDCG writeDefaultConfig:FILE_DATA_GESTURE];
    [statusTV setStringValue:@"Reloading All Gesture Data...."];
    [self reloadDATA];
    [statusTV setStringValue:@"Reloaded All Gesture Data"];
}
//-------------------------------------
- (IBAction)MNRemoveNext:(id)sender{
    [statusTV setStringValue:@"Delete Next Gesture"];
    fileFunc* ftmp=[[fileFunc alloc]init];
    [ftmp open:FILE_DATA_GESTURE :"w++"];
    [ftmp deleteID:1];
    [statusTV setStringValue:@"Deleted Next Gesture"];
}
- (IBAction)MNRemoveBack:(id)sender{
    [statusTV setStringValue:@"Delete Back Gesture"];
    fileFunc* ftmp=[[fileFunc alloc]init];
    [ftmp open:FILE_DATA_GESTURE :"w++"];
    [ftmp deleteID:2];
    
    [statusTV setStringValue:@"Deleted Back Gesture"];
}
- (IBAction)MNRemovePlayScript:(id)sender{
    [statusTV setStringValue:@"Delete Play Script Gesture"];
    fileFunc* ftmp=[[fileFunc alloc]init];
    [ftmp open:FILE_DATA_GESTURE :"w++"];
    [ftmp deleteID:3];
    
    [statusTV setStringValue:@"Deleted Play Script Gesture"];
}
- (IBAction)MNRemoveResetCameraView:(id)sender{
    [statusTV setStringValue:@"Delete Reset Camera View Gesture"];
    fileFunc* ftmp=[[fileFunc alloc]init];
    [ftmp open:FILE_DATA_GESTURE :"w++"];
    [ftmp deleteID:4];
    
    [statusTV setStringValue:@"Deleted Reset Camera View Gesture"];
}
-(void)getIsLearnning{
    isLearning=!isLearning;
    if(isLearning){
        printf("Start Learn");
        [gestureFile open:FILE_DATA_GESTURE :"a+"];
    }else{
        [gestureFile reload];
        printf("Stop Learn");
        //[gestureFile open:FILE_DATA_GESTURE :"r+"];
        //reset Softmax
        
    }
    //printf("Reset draw 6:");
    [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
}
- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertAlternateReturn) {
        return nil;
    } else {
        NSAssert1(NO, @"Invalid input dialog button %d", button);
        return nil;
    }
}
- (int) getMode{//get mode -> edit screen, button....
    return mode;
}
- (IBAction)MNConnectServer:(id)sender{
    NSString* tmp=[self input:@"ホストのアドレス:" defaultValue:@"ccx00.sfc.keio.ac.jp"];
    if(tmp==nil) return;
    NSString* nName=[self input:@"あなたのニックネーム(最大は8文字):" defaultValue:@"noname"];
    if(nName==nil) return;
    nickname=strdup("        ");//8 backspace
    memcpy(nickname, nName.UTF8String, strlen(nName.UTF8String));
    printf("Get %s %s-\n",tmp.UTF8String,nickname);
    HOST=strdup(tmp.UTF8String);
    if([self getDataServer]>=0){
        dispatch_async(dispatch_get_main_queue(), ^{
            //printf("Reset draw 7:");
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 2000, 600)];
        });
        [statusTV setStringValue:@"コネクトができた"];
        
    }else{
        [statusTV setStringValue:@"コネクトができなかった"];
    }
    if([self getMode]!=TIME_INCREASE){//if not TIME INCREASE mode -> hide button control
        [controlBT setTransparent:true];
    }else{
        [controlBT setTransparent:false];
    }
}
- (IBAction)MNDisconnectServer:(id)sender{
    [self notConnectServer];
}
-(bool )getNotGetFrame{
    getFrame=!getFrame;
    return getFrame;
}
- (IBAction)MNgetNotGetFrame:(id)sender{
    if([self getNotGetFrame]){
        [statusTV setStringValue:@"カメラフラ-ムを取る:true"];
        write(sockCamera, "W" , 1);
    }
    else {
        [statusTV setStringValue:@"カメラフラ-ムを取る:false"];
        write(sockCamera, "C" , 1);
    }
    
}
- (bool) sendRequestControlCam{
    if(mode!=TIME_INCREASE) return false;
    if(statusRequest!=2){
        write(svSock, WANT_CONTROL_CAMERA, 3);//send request for get camera Client IP
        statusRequest=1;
    }
    else write(svSock, ESCAPE_CONTROL_CAMERA, 3);//send request for get camera Client IP
    //isRequesting=!isRequesting;
    
    return isRequesting;
}
- (IBAction)BTClickControlBT:(id)sender{
    if(mode!=TIME_INCREASE) return;
    
    if(![self sendRequestControlCam]){
        //[controlBT setTitle:@"Requesting"];
    }else{
        //[controlBT setTitle:@"Request"];
    }
}
@end
