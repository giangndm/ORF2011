#include <stdio.h>
#include <time.h>
#include <math.h>
//float centerX,centerX,rotate,zoom;
#define NUM_MAX_CLIENT 100
#define NUM_MAX_HOST 100
#define NUM_MAX_GROUP 2
#define CAMERA_CLIENT 'C'
#define USER_CLIENT 'U'
#define CONTROL_CAMERA 'L'
#define alpha 0.5
#define THRESHOLD 1
#define THRESHOLD_CONTROL_CAMERA 0.2
typedef struct _clientData{
    long long timeUpdate;
    int camnum;
    float weight;
    float centerx;
    float centery;
    float rotateN;
    float zoomN;
}sumData;
sumData groupSum[NUM_MAX_CLIENT];
sumData biggestG[4];
int numGroup;
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
void initGroup(){
    int i,j;
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

int checkIn(sumData a,sumData b){
    float delX,delY;
    delX=(a.centerx-b.centerx)>0?(a.centerx-b.centerx):(b.centerx-a.centerx);
    delY=(a.centery-b.centery)>0?(a.centery-b.centery):(b.centery-a.centery);
    //printf("%f %f delX=%f --  %f %f dely=%f\n",a.centerx,b.centerx,delX,a.centery,b.centery,delY);
    if((delX<a.zoomN/2&&delY<a.zoomN/2)||(delX<b.zoomN/2&&delX<b.zoomN/2)){
        return 1;
    }
    return 0;
}
void printG(sumData dt,char* msg){
    //printf("%s %d %f %f %f %f %f\n",msg,dt.camnum,dt.centerx,dt.centery,dt.zoomN,dt.rotateN,dt.weight);
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
    long long timeU;
    float w1,w2;
    int checkOverlap;
    int checkNotFoundGroup=1;
    int thresholdID=-1;
    sumData tmp;
    printf("RQ:%f %f %f %f\n",centerx,centery,zoomN,rotateN);
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
            numGroup++;
        }else if(thresholdID>=0){
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
        //get 4 element biggest
        for(i=0;i<4&&i<numGroup;i++){
            if(checkThreshControlCamera(groupSum[i],biggestG[i])){
                //printf("* %f ",groupSum[i].weight);
                break;
            }
        }
    }else{
        sendRequest(camSock,camnum,centerx,centery,rotateN,zoomN);
    }
    //cacult
    //centerX=centerx;
    //camID=camnum;
    //centerY=centery;
    //rotate=rotateN;
    //zoom=zomN;
    //
}
