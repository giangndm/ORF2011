#include <stdio.h>
#include <time.h>
#include <math.h>
//float centerX,centerX,rotate,zoom;
#define LAYER0 1
#define LAYER1 1.5
#define LAYER2 2.2
#define LAYER3 3.5
#define NUM_MAX_CLIENT 100
#define NUM_MAX_HOST 100
#define NUM_MAX_GROUP 100
#define CAMERA_CLIENT 'C'
#define USER_CLIENT 'U'
#define CONTROL_CAMERA 'L'
#define THRESHOLD 1
#define THRESHOLD_CONTROL_CAMERA 0.005
#define  ratioOverlap 0.4
typedef struct _viewerCamera{
    int camnum;
    float centerx;
    float centery;
    float rotateN;
    float zoomN;
    //output window
    float centerxO;
    float centeryO;
    float zoomNO;
}viewerCamera;
typedef struct _clientData{
    int idG;
    long long timeUpdate;
    int camnum;
    float weight;
    float centerx;
    float centery;
    float rotateN;
    float zoomN;
}sumData;

int maxIdG=-1;
sumData groupSum[NUM_MAX_CLIENT];
int tmpGroupSend[4]={0,0,0,0};//0 is default (id start from 1)
int listGroupSend[4]={0,0,0,0};
sumData biggestG[4];
viewerCamera sendViewer[4];
int numGroup;
static float alpha= 0.1;
void sendData(int sock,char* data,int dataSize){
    write(sock, data, dataSize);
}
char* convertData(char* output,int camNum,float centerRateX,float centerRateY ,float rotateN,float  zoomN){
    output[0]=CONTROL_CAMERA;
    memcpy(output+1, &camNum, sizeof(int));
    memcpy(output+1+(sizeof(int))/sizeof(char), &centerRateX, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*1)/sizeof(char), &centerRateY, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*2)/sizeof(char), &rotateN, sizeof(float));
    memcpy(output+1+(sizeof(int)+sizeof(float)*3)/sizeof(char), &zoomN, sizeof(float));
    return output;
}
void sendRequest(int camSock,int camNum,float centerRateX,float centerRateY ,float rotateN,float  zoomN){
    char data[sizeof(float)*4+sizeof(int)+sizeof(char)];
    convertData(data,camNum,centerRateX,centerRateY,rotateN,zoomN);
    sendData(camSock,data,sizeof(float)*4+sizeof(int)+sizeof(char));
}
void sendNew(int camSock,char numViewer){
    char data[sizeof(char)*2+sizeof(viewerCamera)*numViewer];
    data[0]=CONTROL_CAMERA;
    data[1]=numViewer;
    memcpy(data+2,sendViewer,sizeof(viewerCamera)*numViewer);
    send(camSock,data,sizeof(char)*2+sizeof(viewerCamera)*numViewer,0);
    printf("sent %d: %d %f %f %f\n",numViewer,sendViewer[0].camnum,sendViewer[0].centerx,sendViewer[0].centery,sendViewer[0].zoomN);
}
void initGroup(float ratio){
    int i,j;
    printf("Enter alpha value(1second -> decrease:e^-alpha,default:0.1) is %f\n",ratio);
    alpha=ratio;
    numGroup=0;
    for(i=0;i<NUM_MAX_GROUP;i++){
        groupSum[i].camnum=-1;//set not using
        groupSum[i].centerx=0;
        groupSum[i].centery=0;
        groupSum[i].zoomN=0;
        groupSum[i].rotateN=0;
        groupSum[i].weight=0;
    }
}
long long getTime(){
    return time(NULL);
}
float fW(long long time,long long time2){
    return exp((time-time2)*alpha);
}
void deleteServerSock(int idskSer){
    //memoryClient[idskSer].skSer=-1;
    
}
int checkPointIn(double centerx,double centery,sumData a){
    double zoom=(a.zoomN>0?a.zoomN:-1*a.zoomN)*ratioOverlap;
    double delX=(a.centerx-centerx)>0?(a.centerx-centerx):(centerx-a.centerx);
    double delY=(a.centery-centery)>0?(a.centery-centery):(centery-a.centery);
    if(delY<zoom&&delX<zoom) return 1;
    else return 0;
}
int checkIn(sumData a,sumData b){
    if(checkPointIn(a.centerx,a.centery,b)||checkPointIn(b.centerx,b.centery,a)) return 1;
    else return 0;
    //
    float delX,delY;
    delX=(a.centerx-b.centerx)>0?(a.centerx-b.centerx):(b.centerx-a.centerx);
    delY=(a.centery-b.centery)>0?(a.centery-b.centery):(b.centery-a.centery);
    printf("*CI*(%d %d):%f %f delX=%f --  %f %f dely=%f\n",a.camnum,b.camnum,a.centerx,b.centerx,delX,a.centery,b.centery,delY);
    if((delX<(a.zoomN>0?a.zoomN:-1*a.zoomN)*ratioOverlap&&delY<(a.zoomN>0?a.zoomN:-1*a.zoomN)*ratioOverlap)||(delX<(b.zoomN>0?b.zoomN:-1*b.zoomN)*ratioOverlap&&delX<(b.zoomN>0?b.zoomN:-1*b.zoomN)*ratioOverlap)){
        //printf("TRUE");
        return 1;
    }
        //printf("FALSE");
    return 0;
}
void printG(sumData dt,char* msg){
    printf("           **%s %d %f %f %f %f %f\n",msg,dt.camnum,dt.centerx,dt.centery,dt.zoomN,dt.rotateN,dt.weight);
}
void InsertSort(sumData *p,int n)   
{   
    int i,j,count=0,move=0,compare=0;   
    sumData temp;
    for(i=1;i<n;i++){    //ÈÏÎªÖ»ÓÐÒ»¸öÊýµÄÇé¿öÏÂÒÑ¾­ÊÇÅÅºÃÐò,¹Êi=0²»¿¼ÂÇ       
        temp=*(p+i);   
        move++;   
        for(j=i-1;j>=0;j--){   
            if(temp.weight<=(p+j)->weight)   
                break;   
            else{    
                *(p+j+1)=*(p+j);   
                move++;   
            }   
            compare++;   
        }   
        *(p+j+1)=temp;   
        move++;   
    }   
}  
int checkThreshControlCamera(sumData old,sumData newD){
    if(old.camnum!=newD.camnum||((old.centerx-newD.centerx)*(old.centerx-newD.centerx)+(old.centery-newD.centery)*(old.centery-newD.centery)+(old.zoomN-newD.zoomN)*(old.zoomN-newD.zoomN)+(old.rotateN-newD.rotateN)*(old.rotateN-newD.rotateN)>THRESHOLD_CONTROL_CAMERA)) return 1;
    return 0;
}
/**
 idskSer is number in skSer array
 **/
void addrequest(int mode,int camSock,int idskSer,int camnum,float centerx,float centery,float rotateN,float zoomN){
    int i,idC,j,k;
    char check[4];
    long long timeU;
    float w1,w2;
    int checkOverlap;
    int checkNotFoundGroup=1;
    int thresholdID=-1;
    sumData tmp;
    printf("RQ:%d %f %f %f %f\n",camnum,centerx,centery,zoomN,rotateN);
    if(mode==1){
        tmp.centerx=centerx;
        tmp.centery=centery;
        tmp.zoomN=zoomN;
        tmp.rotateN=rotateN;
        //
        timeU=getTime();
        w2=1;
        for(i=0;i<numGroup;i++){
            w1=fW(groupSum[i].timeUpdate,timeU);
            if(groupSum[i].camnum==camnum && checkIn(groupSum[i],tmp)){
                checkNotFoundGroup=0;
                printf("    add to oldGroup %d %lld %lld %f:\n",i,timeU,groupSum[i].timeUpdate,w1);
                printG(groupSum[i],"");
                groupSum[i].centerx=(groupSum[i].centerx*w1*groupSum[i].weight+centerx*w2)/(groupSum[i].weight*w1+w2);
                groupSum[i].centery=(groupSum[i].centery*w1*groupSum[i].weight+centery*w2)/(groupSum[i].weight*w1+w2);
                groupSum[i].zoomN=(groupSum[i].zoomN*w1*groupSum[i].weight+zoomN*w2)/(groupSum[i].weight*w1+w2);
                groupSum[i].rotateN=(groupSum[i].rotateN*w1*groupSum[i].weight+rotateN*w2)/(groupSum[i].weight*w1+w2);
                groupSum[i].timeUpdate=timeU;
                groupSum[i].weight=groupSum[i].weight*w1+w2;
                printG(groupSum[i],"    -> new:");
                checkOverlap=1;
                while (checkOverlap==1) {
                    checkOverlap=0;
                    printf("        Check Over Lap:\n");
                    //check if group is overlap
                    for(j=0;j<numGroup;j++)if(j!=i){
                        if(groupSum[i].camnum==groupSum[j].camnum&&checkIn(groupSum[i],groupSum[j])){
                            printf("            Overlap %d %d\n",i,j);
                            checkOverlap=1;
                            if(j>i) groupSum[j].weight*=fW(groupSum[j].timeUpdate,timeU);
                            groupSum[i].centerx=(groupSum[i].centerx*groupSum[i].weight+groupSum[j].centerx*groupSum[j].weight)/(groupSum[j].weight+groupSum[i].weight);
                            groupSum[i].centery=(groupSum[i].centery*groupSum[i].weight+groupSum[j].centery*groupSum[j].weight)/(groupSum[j].weight+groupSum[i].weight);
                            groupSum[i].zoomN=(groupSum[i].zoomN*groupSum[i].weight+groupSum[j].zoomN*groupSum[j].weight)/(groupSum[j].weight+groupSum[i].weight);
                            groupSum[i].rotateN=(groupSum[i].rotateN*groupSum[i].weight+groupSum[j].rotateN*groupSum[j].weight)/(groupSum[j].weight+groupSum[i].weight);
                            groupSum[i].weight+=groupSum[j].weight;
                            //delete at j position
                            for(k=j;k<numGroup-1;k++){
                                groupSum[k]=groupSum[k+1];
                            }
                            numGroup--;
                            if(i>j) i--;
                            break;
                        }
                    }
                }
            }else{
                groupSum[i].weight*=w1;
                if(groupSum[i].weight<THRESHOLD) thresholdID=i;
            }
        }
        if(checkNotFoundGroup&&numGroup<NUM_MAX_GROUP){
            printf("    NOT FOUND GROUP -> CREATE NEW GROUP AT END %d\n",numGroup);
            groupSum[numGroup].centerx=centerx;
            groupSum[numGroup].centery=centery;
            groupSum[numGroup].zoomN=zoomN;
            groupSum[numGroup].rotateN=rotateN;
            groupSum[numGroup].camnum=camnum;
            groupSum[numGroup].timeUpdate=getTime();
            groupSum[numGroup].weight=1;
            groupSum[numGroup].idG= numGroup+1;            
            numGroup++;
        }else if(checkNotFoundGroup&&thresholdID>=0){
            printf("    NOT FOUND GROUP -> CREATE NEW GROUP AT THRESHOLD %d\n",thresholdID);
            groupSum[thresholdID].centerx=centerx;
            groupSum[thresholdID].centery=centery;
            groupSum[thresholdID].zoomN=zoomN;
            groupSum[thresholdID].rotateN=rotateN;
            groupSum[thresholdID].camnum=camnum;
            groupSum[thresholdID].timeUpdate=getTime();
            groupSum[thresholdID].weight=1;
        }
        /*FIND 4th bigest*/
        InsertSort(groupSum,numGroup);
        /**/
        printf("\n%d\n",numGroup);
        for(k=0;k<4&&k<numGroup;k++){
            printG(groupSum[k],"MAX**:");
        }
        if(numGroup>=1){
            if(numGroup==1||groupSum[0].weight>LAYER2*groupSum[1].weight){//only one viewer
                sendViewer[0].centerx=groupSum[0].centerx;
                sendViewer[0].centery=groupSum[0].centery;
                sendViewer[0].zoomN=groupSum[0].zoomN;
                sendViewer[0].rotateN=groupSum[0].rotateN;
                sendViewer[0].camnum=groupSum[0].camnum;
                //
                sendViewer[0].centerxO=0.5;
                sendViewer[0].centeryO=0.5;
                sendViewer[0].zoomNO=1;
                //
                sendNew(camSock,1);
            }else if(numGroup==2||groupSum[1].weight>LAYER2*groupSum[2].weight){
                //
                sendViewer[0].centerxO=0.5;
                sendViewer[0].centeryO=0.5;
                sendViewer[0].zoomNO=1;
                sendViewer[0].centerx=groupSum[0].centerx;
                sendViewer[0].centery=groupSum[0].centery;
                sendViewer[0].zoomN=groupSum[0].zoomN;
                sendViewer[0].rotateN=groupSum[0].rotateN;
                sendViewer[0].camnum=groupSum[0].camnum;
                //
                //
                sendViewer[1].centerxO=0.85;
                sendViewer[1].centeryO=0.85;
                sendViewer[1].zoomNO=0.3;
                sendViewer[1].centerx=groupSum[1].centerx;
                sendViewer[1].centery=groupSum[1].centery;
                sendViewer[1].zoomN=groupSum[1].zoomN;
                sendViewer[1].rotateN=groupSum[1].rotateN;
                sendViewer[1].camnum=groupSum[1].camnum;
                //
                sendNew(camSock,2);
                
            }
            else if(groupSum[0].weight<=LAYER3*groupSum[1].weight&&groupSum[0].weight>LAYER1*groupSum[1].weight){//send 1big, 3tiny
                //set id for best tranfromer
                listGroupSend[0]=0;
                tmpGroupSend[0]=groupSum[0].idG;
                /*
                 tmpGroup save list idG of pre sent group
                 
                 */
                //save
                //
                printf("CHeck 3tiny:");
                for(k=1;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d)",groupSum[k].idG,tmpGroupSend[k]);
                printf("\n");
                
                for(k=1;k<(numGroup>=4?4:numGroup);k++) listGroupSend[k]=-1;
                for(k=1;k<(numGroup>=4?4:numGroup);k++){
                    for(j=1;j<(numGroup>=4?4:numGroup);j++){
                        if(tmpGroupSend[j]==groupSum[k].idG){//if is same -> not change
                            listGroupSend[j]=k;
                            groupSum[k].idG*=-1;
                            break;
                        }
                    }
                }
                printf("CHeck 3tiny2:");
                for(k=1;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d*%d)",groupSum[k].idG,tmpGroupSend[k],listGroupSend[k]);
                printf("\n");
                for(k=1;k<(numGroup>=4?4:numGroup);k++){
                    if(listGroupSend[k]==-1){//haven't date to send -> find data
                        for(j=1;j<(numGroup>=4?4:numGroup);j++) if(groupSum[j].idG > 0){
                            tmpGroupSend[k]=groupSum[j].idG;
                            listGroupSend[k]=j;
                            groupSum[j].idG*=-1;
                            break;
                        }
                        if(listGroupSend[k]==-1){
                            printf("Fix error\n");
                            for(j=1;j<(numGroup>=4?4:numGroup);j++) listGroupSend[j]=0;
                            for(j=1;j<(numGroup>=4?4:numGroup);j++) if(listGroupSend[j]>=0) check[listGroupSend[j]]=1;
                            for(j=1;j<(numGroup>=4?4:numGroup);j++) if(check[j]==0){
                                listGroupSend[k]=j;
                                break;
                            }
                        }
                    }
                }
                printf("CHeck 3tiny3:");
                for(k=1;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d*%d)",groupSum[k].idG,tmpGroupSend[k],listGroupSend[k]);
                printf("\n");
                printf("List send 3tiny:");
                for(k=1;k<(numGroup>=4?4:numGroup);k++) {
                    if(groupSum[k].idG<0) groupSum[k].idG*=-1;
                    printf("%d ",listGroupSend[k]);                        
                }
                printf("\n");
                //

                //
                for(k=0;k<(numGroup>=4?4:numGroup);k++){
                    sendViewer[k].centerx=groupSum[listGroupSend[k]].centerx;
                    sendViewer[k].centery=groupSum[listGroupSend[k]].centery;
                    sendViewer[k].zoomN=groupSum[listGroupSend[k]].zoomN;
                    sendViewer[k].rotateN=groupSum[listGroupSend[k]].rotateN;
                    sendViewer[k].camnum=groupSum[listGroupSend[k]].camnum;
                }
                //
                sendViewer[0].centerxO=0.5;
                sendViewer[0].centeryO=0.35;
                sendViewer[0].zoomNO=0.7;
                //
                //
                
                sendViewer[1].centerxO=1-0.15;
                sendViewer[1].centeryO=1-0.15;
                sendViewer[1].zoomNO=0.28;
                //
                sendViewer[2].centerxO=0.5;
                sendViewer[2].centeryO=1-0.15;
                sendViewer[2].zoomNO=0.28;

                sendViewer[3].centerxO=0.15;
                sendViewer[3].centeryO=1-0.15;
                sendViewer[3].zoomNO=0.28;                
                sendNew(camSock,(numGroup>=4?4:numGroup));
            }else {//4 same size
                //
                printf("CHeck 4same:");
                for(k=0;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d)",groupSum[k].idG,tmpGroupSend[k]);
                printf("\n");
                
                for(k=0;k<(numGroup>=4?4:numGroup);k++) listGroupSend[k]=-1;
                for(k=0;k<(numGroup>=4?4:numGroup);k++){
                    for(j=0;j<(numGroup>=4?4:numGroup);j++){
                        if(tmpGroupSend[j]==groupSum[k].idG){//if is same -> not change
                            listGroupSend[j]=k;
                            groupSum[k].idG*=-1;
                            listGroupSend[j]=k;
                            break;
                        }
                    }
                }
                printf("CHeck 4same2:");
                for(k=0;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d*%d)",groupSum[k].idG,tmpGroupSend[k],listGroupSend[k]);
                printf("\n");
                for(k=0;k<(numGroup>=4?4:numGroup);k++){
                    if(listGroupSend[k]==-1){//haven't date to send -> find data
                        for(j=0;j<(numGroup>=4?4:numGroup);j++) if(groupSum[j].idG > 0){
                            tmpGroupSend[k]=groupSum[j].idG;
                            listGroupSend[k]=j;
                            groupSum[j].idG*=-1;
                            break;
                        }
                        if(listGroupSend[k]==-1){
                            printf("Fix error\n");
                            for(j=0;j<(numGroup>=4?4:numGroup);j++) listGroupSend[j]=0;
                            for(j=0;j<(numGroup>=4?4:numGroup);j++) if(listGroupSend[j]>=0) check[listGroupSend[j]]=1;
                            for(j=0;j<(numGroup>=4?4:numGroup);j++) if(check[j]==0){
                                listGroupSend[k]=j;
                                break;
                            }
                        }
                    }
                }
                printf("CHeck 4same3:");
                for(k=0;k<(numGroup>=4?4:numGroup);k++) printf("(%d %d*%d)",groupSum[k].idG,tmpGroupSend[k],listGroupSend[k]);
                printf("\n");
                printf("List send same:");
                for(k=0;k<(numGroup>=4?4:numGroup);k++) {
                    if(groupSum[k].idG<0) groupSum[k].idG*=-1;
                    printf("%d ",listGroupSend[k]);                        
                }
                printf("\n");
                //
                for(k=0;k<(numGroup>=4?4:numGroup);k++){
                    sendViewer[k].centerx=groupSum[listGroupSend[k]].centerx;
                    sendViewer[k].centery=groupSum[listGroupSend[k]].centery;
                    sendViewer[k].zoomN=groupSum[listGroupSend[k]].zoomN;
                    sendViewer[k].rotateN=groupSum[listGroupSend[k]].rotateN;
                    sendViewer[k].camnum=groupSum[listGroupSend[k]].camnum;
                }
                //
                sendViewer[0].centerxO=0.25;
                sendViewer[0].centeryO=0.25;
                sendViewer[0].zoomNO=0.48;
                //
                //
                sendViewer[1].centerxO=0.75;
                sendViewer[1].centeryO=0.75;
                sendViewer[1].zoomNO=0.48;
                //
                sendViewer[2].centerxO=0.25;
                sendViewer[2].centeryO=0.75;
                sendViewer[2].zoomNO=0.48;
                //
                sendViewer[3].centerxO=0.75;
                sendViewer[3].centeryO=0.25;
                sendViewer[3].zoomNO=0.48;
                
                sendNew(camSock,(numGroup>=4?4:numGroup));
            }
        }
    }else if(mode==0||mode==2){
        sendViewer[0].centerx=centerx;
        sendViewer[0].centery=centery;
        sendViewer[0].zoomN=zoomN;
        sendViewer[0].rotateN=rotateN;
        sendViewer[0].camnum=camnum;
        //
        sendViewer[0].centerxO=0.5;
        sendViewer[0].centeryO=0.5;
        sendViewer[0].zoomNO=1;
        //
        sendNew(camSock,1);
    }
    //cacult
    //centerX=centerx;
    //camID=camnum;
    //centerY=centery;
    //rotate=rotateN;
    //zoom=zomN;
    //
}
