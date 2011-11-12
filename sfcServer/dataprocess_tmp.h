#include <stdio.h>
#include <time.h>
//float centerX,centerX,rotate,zoom;
#define NUM_MAX_CLIENT 100
#define NUM_MAX_HOST 100
#define CAMERA_CLIENT 'C'
#define USER_CLIENT 'U'
#define CONTROL_CAMERA 'L'
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
long long getTime(){
    time_t timer;                // Define the timer
    struct tm *tblock;           // Define a structure for time block
    timer = time(NULL);
}
float functionWeightTime(long long time){
    
}
void addrequest(int camSock,int camnum,float centerx,float centery,float rotateN,float zoomN){
    
    //centerX=centerx;
    //camID=camnum;
    //centerY=centery;
    //rotate=rotateN;
    //zoom=zomN;
    sendRequest(camSock,camnum,centerx,centery,rotateN,zoomN);
}
