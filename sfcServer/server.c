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
#include <math.h>
#include <sys/time.h>
#include "dataprocess.h"
#define NUM_MAX_CLIENT 100
#define NUM_MAX_HOST 100
#define SET_FPS 'F'
#define CAMERA_CLIENT 'C'
#define USER_CLIENT 'U'
#define SERVER_CONTROL_CLIENT 'S'
#define CONTROL_CAMERA 'L'
#define CAMERA_LIST_REQUEST 'R'
#define WANT_VIEW_CAMERA 'W'
#define WANT_CONTROL_CAMERA 'A'//using for imcrease time strategy
#define ESCAPE_CONTROL_CAMERA 'E'//using for imcrease time strategy
#define SEND_LIST_ROUNDROBIN 'I'//using for ROUND ROBIN
#define CONTROL_MOTOR 'M'
#define MOTOR_CLIENT 'H'
#define TIME_INCREASE 2
#define ROUND_ROBIN 0
#define WEIGHT_AVG 1

/* 
 khai bao bien
 */
pthread_t pth,pthTimeIncrease;
int mode;//roundrobin or other?
//define for roundrobin
//int nowActive[2]={0,0};
int map[NUM_MAX_CLIENT+2];
int numClient;
//end of define for roundrobin
int len; 
char buf[1024];//using to get info of client and recv data from client
char *port="1412";
char ibuf[1024],pbuf[200];//store info port
int size,i,l,j;//using for loop
ssize_t numBytesRcvd;//size of Recv data from client/
struct addrinfo hints,*addrList,*a0;//using to get info of HOST to creat socket
struct sockaddr newSk_addr;//using to get info of client
int newSk_len,buf_len;
fd_set readfds,fdsSer;//using to create multi socket listten
int skSer[NUM_MAX_CLIENT];//array store socket of 
char skNickName[NUM_MAX_CLIENT*8];
int skHost[NUM_MAX_HOST];
char* skSerIP[NUM_MAX_CLIENT];//array store IP of 
char* skSerPort[NUM_MAX_CLIENT];//array store port of 
int newSK;
int numHost=0;
int cameraSock;
char ipcamera[100];
/*store camera info*/
char* cameraInfo=NULL;
int cameraInfoLen=0;
char cameraIP[1024];
int cameraID=-1;
//for increase time mode
//for control server
int sockControlServerID=-1;
//for round robin mode
int timePriod=5;
//for control motor
int motorSock;
int motorID;

typedef struct _timeIncrease{
    float* clientTime;
    char* requesting;
    struct timeval* lastTime;
    int* ipClient;
    int clientControling;//-1 if not busy,else store id in array of client
    float alpha_time;
    int max_time;
}timeIncreaseData;
int max_time;
int default_time;
float alpha_time;
char requesting[NUM_MAX_CLIENT];
struct timeval lastTime[NUM_MAX_CLIENT];
float clientTime[NUM_MAX_CLIENT];
float tmpTime;
timeIncreaseData tIDATA;
struct timeval tmpTimeVal;

int framePerSecond=4;
int tmpFramePerSecond;

/**/
char* getName(int sockID){
    int i;
    for(i=0;i<NUM_MAX_CLIENT;i++){
        if(skSer[i]==sockID){
            return skNickName+8*i;
        }
    }
}
void sendListNameToClient(){
    char buff[1024];
    int count=0,i;
    for(i=0;i<NUM_MAX_CLIENT;i++) if(i!=motorID&& i!=cameraID&&i!=sockControlServerID&& skSer[i]>0){ 
        
        
        memcpy(sizeof(int)+sizeof(char)+buff+8*(count),skNickName+8*i,8);
        printf("copy %s\n",(sizeof(int)+sizeof(char)+buff+8*(i)));
        count++;
    }
    buff[0]=SEND_LIST_ROUNDROBIN;
    buff[sizeof(int)+sizeof(char)+count*8]='\0';
    printf("%c %d %d %s\n",buff[0],*(int*)(buff+1),sizeof(int)+sizeof(char)+count*8,buff+sizeof(int)+1);
    
    for(i=0;i<NUM_MAX_CLIENT;i++) if(skSer[i]>0){
        write(skSer[i],buff,sizeof(int)+sizeof(char)+count*8+1);
        printf("    send to %d %d %s\n",*(int*)(buff+1),count,buff+sizeof(int)+1);        
    }
}
void* threadRoundRobin(void* arg){
    int* map=(int*)arg;
    char buff[1024];
    printf("Started robin mode\n");
    int i,count;
    while(1){
        printf("Switch from %d %d\n",map[0],map[1]);
        sleep(timePriod);
        if(map[1]<=0) continue;
        write(map[map[0]+2],"S",1);//stop
        map[0]++;
        if(map[0]>=map[1]) map[0]=0;
        printf("now switch to client %d %d\n",map[0],map[map[0]+2]);
        /*talk to client*/
        buff[0]='O';
        *(int*)(buff+1)=timePriod;
        write(map[map[0]+2],buff,1+sizeof(int));//OK
        //send info to all client
        buff[0]=SEND_LIST_ROUNDROBIN;
        *(int*)(buff+1)=map[1];
        count=0;
        memcpy(sizeof(int)+sizeof(char)+buff+8*(count),getName(map[map[0]+2]),8);
        count=1;
        for(i=map[0]+3;i<map[1]+2;i++,count++) memcpy(sizeof(int)+sizeof(char)+buff+8*(count),getName(map[i]),8);
        for(i=2;i<map[0]+2;i++,count++) memcpy(sizeof(int)+sizeof(char)+buff+8*(count),getName(map[i]),8);
        buff[sizeof(int)+sizeof(char)+map[1]*8]='\0';
        printf("%c %d %d %s\n",buff[0],*(int*)(buff+1),sizeof(int)+sizeof(char)+map[1]*8,buff+sizeof(int)+1);
        
        for(i=2;i<map[1]+2;i++) if(i!=map[0]+2||1){//try not check controlling client -> send to all
            usleep(100000);
            write(map[i],buff,sizeof(int)+sizeof(char)+map[1]*8+1);
            
            printf("    send to %d %d %s\n",*(int*)(buff+1),map[i],buff+sizeof(int)+1);
        }        
        //
    }
}
float difTime(struct timeval t1,struct timeval t2){
    float dif=(t2.tv_usec + 1000000 * t2.tv_sec) - (t1.tv_usec + 1000000 * t1.tv_sec);
    printf("dif:%f\n",dif);
    return dif;
}
void* threadTimeIncrease(void* arg){
    char buf[100];
    int i;
    int max=-1;
    int preControling=-1;
    timeIncreaseData* data= (timeIncreaseData*)arg;
    printf("Started timeIncrease mode\n");
    while(1){
        printf("Update timeIncrease %d:",data->clientControling);
        
        for(i=0;i<NUM_MAX_CLIENT;i++)if((data->ipClient)[i]>0&&i!=cameraID && i!= sockControlServerID && i!= motorID){//update time
            gettimeofday(&tmpTimeVal, NULL);
            if(i!=data->clientControling){//plus for waiting

                if((data->clientTime)[i]<data->max_time)(data->clientTime)[i]+=difTime((data->lastTime)[i],tmpTimeVal)*(data->alpha_time)/1000000;
                if((data->clientTime)[i]>data->max_time)(data->clientTime)[i]=data->max_time;
            }else{//minus because controling
                
                (data->clientTime)[i]-=difTime((data->lastTime)[i],tmpTimeVal)/1000000;
                if((data->clientTime)[i]<=0){
                    data->clientControling=-1;
                    (data->requesting)[i]=0;
                    printf("Stop control because havent time %d %d\n",i,data->clientControling);
                    buf[0]='S';
                    tmpTime=(data->clientTime)[i];
                    printf("Sent time1:%f\n",tmpTime);
                    memcpy(buf+1,&tmpTime,sizeof(float));
                    write((data->ipClient)[i],buf,sizeof(char)+sizeof(float));
                    (data->clientTime)[i]=0;
             
                }
            }
            (data->lastTime)[i]=tmpTimeVal;
            printf("%f,",(data->clientTime)[i]);
        }
        printf("\n");
        if(data->clientControling<0||data->clientControling>=NUM_MAX_CLIENT){//if not busy -> caculate time of all requesting client and choice one client
            max=-1;
            for(i=0;i<NUM_MAX_CLIENT;i++) if((data->ipClient)[i]>0&&(data->requesting)[i]==1&&(data->clientTime)[i]>0){
                if(max==-1||(data->clientTime)[i]>(data->clientTime)[max]) max=i;
            }
            if(max!=-1){//if choiced else -> dont have request
                buf[0]='O';
                tmpTime=(data->clientTime)[max];
                printf("Sent time2:%f\n",tmpTime);
                memcpy(buf+1,&tmpTime,sizeof(float));
                write((data->ipClient)[max],buf,sizeof(char)+sizeof(float));//send OK to choiced client
                data->clientControling=max;
            }else if(preControling!=data->clientControling){//if havent-> notify for all client]
                for(i=0;i<NUM_MAX_CLIENT;i++) if((data->ipClient)[i]>0){
                    
                    buf[0]='F';
                    tmpTime=(data->clientTime)[i];
                    printf("Sent time3:%f\n",tmpTime);
                    memcpy(buf+1,&tmpTime,sizeof(float));
                    write((data->ipClient)[i],buf,sizeof(char)+sizeof(float));
                }
            }
            preControling=data->clientControling;
        }
        usleep(500000);
        
    }
}
void initSocket(){
    memset(&hints,0,sizeof(hints));//set all bit of hints to default (0)
    hints.ai_family     = AF_UNSPEC;//acc all type of IPV4 and IPV6
    hints.ai_socktype   =SOCK_STREAM;//acc only stream
    hints.ai_flags      =AI_PASSIVE;
    if(getaddrinfo(NULL,port,&hints,&addrList)){
        perror("Cannot get name info");
        return ;
    }
    for(a0=addrList;a0;a0=a0->ai_next){
        if(numHost==NUM_MAX_HOST) break;//exit loop if skHost if full
        //get nameinfo
        if(getnameinfo(a0->ai_addr,a0->ai_addrlen,ibuf,1024,pbuf,20,NI_NUMERICHOST|NI_NUMERICSERV)){//get name info of host and check if cannot!
            perror("Cannot get name info\n");
            sprintf(ibuf,"???");
            sprintf(pbuf,"???");
        }
        printf("%s %s %d\n",ibuf,pbuf,a0->ai_family);
        //
        skHost[numHost]= socket(a0->ai_family,a0->ai_socktype,a0->ai_protocol);//create socket
        if(skHost[numHost]<0){//check if false creat socket
            perror("Cannot create socket\n");
            continue;
        }
        if(a0->ai_family== AF_INET6){//check if is IPV6
            int on=1;
            if(setsockopt(skHost[numHost], IPPROTO_IPV6, IPV6_V6ONLY,&on,sizeof(on))<0){//if is IPV6-> config for IPV6
                perror("Setsockopt v6");
                close(skHost[numHost]);//if cannot config -> close socket
                continue;
            }
        }
        /*Setting for multi connect*/
        printf("a\n");
        int flag= fcntl(skHost[numHost],F_GETFL);
        if(fcntl(skHost[numHost],F_GETFL,flag|O_NONBLOCK)<0){
            perror("Fcntl erro\n");
            continue;
        }
        int opt=1;
        printf("b\n");
        setsockopt(skHost[numHost], SOL_SOCKET, SO_REUSEADDR, 
                   (char *)&opt, sizeof(opt)) ;
        //end of setting
        printf("c\n");
        if(bind(skHost[numHost],a0->ai_addr,a0->ai_addrlen)<0){
            perror("Cannot bind connect\n");
            continue;
        }
        printf("d\n");
        if(listen(skHost[numHost],10)<0){
            perror("Listen false\n");
            continue;
        }
        numHost++;
        printf("Connect ok\n");
        
        
    }
    printf("Sum %d\n",numHost);
    freeaddrinfo(addrList);
}
void updateModeToClient(char* buf,int Size){
    int j;
    printf("Begin send new config to all client:\n");
    for(j=0;j<NUM_MAX_CLIENT;j++)if(skSer[j]>0&&j!=cameraID&&j!=sockControlServerID && j!= motorID){
        printf("    Send new config to %d %d\n",j,skSer[j]);
        write(skSer[j],buf,Size);
    }
    
}
void updateRoundRobin(int id){
    int i,tmp=-1;
    if(id>=0){
        map[2+map[1]++]=id;
    }else{
        id+=1;
        id*=-1;
        map[1]--;
        for(i=0;i<map[1];i++) if(map[i+2]==id) tmp=i;
        if(tmp<0){
            printf("Error update roundrobin\n");
            return;
        }
        for(i=tmp;i<map[1];i++) map[i+2]= map[i+3];
    }
}
void setRoundRobinMode(int timePr){
    char buf[10];
    int i;
    printf("-----%d------\n",timePr);
    if(mode==0&&timePr==timePriod){
        printf("\n**************\nalready in roundrobin mode\n**************\n");
        return;
    }
    if(mode==0){//if already in roundrobin mode
        printf(" ****\nUpdate roundrobin timePriod %d to %d\n*******\n",timePriod,timePr);
        timePriod=timePr;
        return;
    }
    //update all exited client to roundrobin mode

    //
    printf(" ****\nSet to roundrobin\n*******\n");
    if(mode==2) pthread_cancel(pthTimeIncrease);
    map[0]=map[1]=0;
    for(i=0;i<NUM_MAX_CLIENT;i++)if(skSer[i]>0&&i!=cameraID&&i!=sockControlServerID&&i!= motorID){
        printf("    update %d (%d) client to roundrobin\n",i,skSer[i]);
        updateRoundRobin(skSer[i]);    
    }
    pthread_create(&pth, NULL, threadRoundRobin,map);
    mode=0;
    buf[0]='N';
    *(int*)(buf+1)=0;
    updateModeToClient(buf,sizeof(int)+sizeof(char));
}
void setWeightedMode(float ratio ){
    char buf[10];
    if(alpha!=ratio||mode!=1){//alpha is varial at dataprocess.h
        printf(" ****\nSet to weighted\n*******\n");
        if(mode==0) pthread_cancel(pth);
        if(mode==2) pthread_cancel(pthTimeIncrease);
        
        if(mode!=1){
            printf("init average\n");  
            initGroup(ratio);
            buf[0]='N';
            *(int*)(buf+1)=1;
            updateModeToClient(buf,sizeof(int)+sizeof(char));
        }
        mode=1;
    }else{
        printf("already in Weight mode\n");
    }
}
void setIncreaseTimeMode(int first,int max,float ratio){
    char buf[20];
    int i;
    if(mode!=2||first!=default_time||max!=max_time||ratio!=alpha_time){
        if(mode==0) pthread_cancel(pth);
        printf(" ****\nSet to IncreaseTimeMode with:%d %d %f\n*******\n",first,max,ratio);
        default_time=first;
        max_time=max;
        alpha_time=ratio;
        //scanf("%d %d %f",&default_time,&max_time,&alpha_time);
        for(i=0;i<NUM_MAX_CLIENT;i++){
            clientTime[i]=-1;
            requesting[i]=0;
        }
        tIDATA.requesting=requesting;        
        tIDATA.clientTime=clientTime;
        tIDATA.lastTime=lastTime;
        tIDATA.ipClient=skSer;
        tIDATA.clientControling=-1;
        tIDATA.alpha_time=alpha_time;
        tIDATA.max_time=max_time;
        //set time to all client
        for(i=0;i<NUM_MAX_CLIENT;i++){
            tIDATA.clientTime[i]=default_time;
            gettimeofday(&tmpTimeVal, NULL);
            tIDATA.lastTime[i]=tmpTimeVal;
        }
        //
        if(mode!=2)pthread_create(&pthTimeIncrease, NULL, threadTimeIncrease,&tIDATA);
        mode=2;
        buf[0]='N';
        *(int*)(buf+1)=2;
        *(int*)(buf+1+sizeof(int))=default_time;
        *(int*)(buf+1+sizeof(int)*2)=max_time;
        *(float*)(buf+1+sizeof(int)*3)=alpha_time;
        updateModeToClient(buf,sizeof(int)+sizeof(char)+sizeof(int)*3+sizeof(float));
    }else{
        printf("already in Time Increase mode\n");
    }
}
int main(){
    char buf2[10];
    int cameranum;
    float centerRateX,centerRateY,rotate,zoom;
    //printf("Enter mode id:");scanf("%d",&mode);
    mode=-1;
    setRoundRobinMode(10);
    srand(1412);
    if(mode==0){//if roundrobin
        
        
    }else if(mode==1){
        
    }else if(mode==2){//if TIME INCREASE
        
    }
    initSocket();
    /*default config of camera is 2*/
    cameraInfoLen=sizeof(char)+sizeof(int)*2+sizeof(float)*2+(sizeof(int)*2+sizeof(float));//plus size of increase time mode
    cameraInfo=(char*)malloc(cameraInfoLen);
    *(int*)(cameraInfo+sizeof(char))=2;
    *(float*)(cameraInfo+sizeof(char)+sizeof(int))=0.75;
    *(float*)(cameraInfo+sizeof(char)+sizeof(int)+sizeof(float))=0.75;
    *(int*)(cameraInfo+sizeof(char)+sizeof(int)+sizeof(float)*2)=mode;
    *(int*)(cameraInfo+sizeof(char)+sizeof(int)*2+sizeof(float)*2)=default_time;
    *(int*)(cameraInfo+sizeof(char)+sizeof(int)*3+sizeof(float)*2)=max_time;
    *(float*)(cameraInfo+sizeof(char)+sizeof(int)*4+sizeof(float)*2)=alpha_time;
    /*Loop listener form soket*/
    for(i=0;i<10;i++) skSer[i]=0;
    while(1){//loop forever for recv msg and accept new connect
        FD_ZERO(&readfds);
        for(l=0;l<numHost;l++ )FD_SET(skHost[l],&readfds);
        for(i=0;i<10;i++)if(skSer[i]>0) FD_SET(skSer[i],&readfds);
        select(10+3, &readfds, NULL, NULL, NULL);
        for(l=0;l<numHost;l++)if(FD_ISSET(skHost[l],&readfds)){//check for new connect of all SOCKET
            printf("NEWC %d\n",l);
            newSk_len=sizeof(newSk_addr);
            newSK= accept(skHost[l],&newSk_addr,&newSk_len);
            //getting info of client
            if(getnameinfo(&newSk_addr,newSk_len,ibuf,1024,pbuf,20,NI_NUMERICHOST|NI_NUMERICSERV)){//get name info of new connect
                perror("Cannot get name info\n");
                sprintf(ibuf,"???");
                sprintf(pbuf,"???");
            }
            printf("Get connect form:%s %s\n",ibuf,pbuf);
            //
            for(i=0;i<NUM_MAX_CLIENT;i++) if(skSer[i]==0){//store socket of new connect
                skSer[i]=newSK;
                skSerIP[i]= strdup(ibuf);
                skSerPort[i]= strdup(pbuf);
                if(mode==2){
                    tIDATA.clientTime[i]=default_time;
                    gettimeofday(&tmpTimeVal, NULL);
                    tIDATA.lastTime[i]=tmpTimeVal;
                }
                break;
            }
            if(i==NUM_MAX_CLIENT) {//check if cannot store new socket (array of socket is full)
                close(newSK);
                printf("Array store client socket is full-> cannot acc connect");
            }
            printf("NEW socket of Client Created\n");
            
        }
        for(i=0;i<NUM_MAX_CLIENT;i++) if(skSer[i]>0&&FD_ISSET(skSer[i],&readfds)){// check new msg of all socket of client
            /* read data from UserBrower */
            numBytesRcvd = recv(skSer[i], buf, 1024, 0);
            if(numBytesRcvd<=0){//close if cant recv data
                printf("Close sock %d->%d\n",i,skSer[i]);
                close(skSer[i]);
                skSer[i]=0;
                
                if(mode==0){//if user roundrobin
                    if(i!=motorID&&i!=cameraID&&i!=sockControlServerID)updateRoundRobin(-1*skSer[i]-1);
                }else if(mode==2){
                    tIDATA.requesting[i]=0;
                    if(tIDATA.clientControling==i) tIDATA.clientControling=-1;
                    printf("Client %d exit->escape control\n",skSer[i]);                
                }
                if(mode!= ROUND_ROBIN)sendListNameToClient();
                continue;
            }
            printf("Recv %c %d - %d  size\n",buf[0],numBytesRcvd,(sizeof(float)*4+sizeof(int)+sizeof(char)));
            if(buf[0]==CAMERA_CLIENT){//if client is camera -> setcamera client
                cameraSock=skSer[i];
                cameraID=i;
                printf("Set camera sock:%d %d size: %d ,number cam:%d %d\n",i,skSer[i],numBytesRcvd,*(int*)(buf+1),sizeof(ibuf));
                if(cameraInfo) free(cameraInfo);
                cameraInfo=(char*)malloc(sizeof(char)*numBytesRcvd+sizeof(int)+sizeof(int)+sizeof(float));
                memcpy(cameraInfo,buf,numBytesRcvd);
                memcpy(cameraInfo+numBytesRcvd,&mode,sizeof(int));//send mode to client
                if(mode==TIME_INCREASE){
                    *(int*)(cameraInfo+sizeof(char)+sizeof(int)+sizeof(float)**(int*)(buf+1))=mode;
                    *(int*)(cameraInfo+sizeof(char)+sizeof(int)*2+sizeof(float)**(int*)(buf+1))=default_time;
                    *(int*)(cameraInfo+sizeof(char)+sizeof(int)*3+sizeof(float)**(int*)(buf+1))=max_time;
                    *(float*)(cameraInfo+sizeof(char)+sizeof(int)*4+sizeof(float)**(int*)(buf+1))=alpha_time;
                    numBytesRcvd+=sizeof(float)+sizeof(int)*2;
                }
                memcpy(cameraIP,ibuf,sizeof(ibuf));
                cameraInfoLen=numBytesRcvd+sizeof(int);
                printf("Store:%s %d %d %f\n",cameraIP,*(int*)(cameraInfo+1),cameraInfoLen,*(float*)(cameraInfo+1+sizeof(int)));
                
            }else if(buf[0]==USER_CLIENT&&numBytesRcvd==(sizeof(float)*4+sizeof(int)+sizeof(char))){
                /*send to all client*/
                printf("Begin send to others client %d %d %c %c:\n",cameraID,sockControlServerID,*(skNickName+8*i),*(skNickName+8*i+1));
                memcpy(buf+(sizeof(char)+sizeof(int)+sizeof(float)*4)/sizeof(char),&i,sizeof(int));//insert ID of client at end of buffer
                memcpy(buf+(sizeof(char)+sizeof(int)*2+sizeof(float)*4)/sizeof(char),skNickName+8*i,8);//insert nickname of client at end of buffer
                for(j=0;j<NUM_MAX_CLIENT;j++)if(skSer[j]>0){
                    printf("    :%d %d\n",j,skSer[j]);
                }
                for(j=0;j<NUM_MAX_CLIENT;j++)if(i!=j&&skSer[j]>0&&j!=cameraID&&j!=sockControlServerID&&j!=motorID){
                    printf("    sent to %d (%d)\n",j,skSer[j]);
                    write(skSer[j],buf,sizeof(char)+sizeof(int)+sizeof(float)*5+8);
                }
                //end of send to all client
                if(mode==0){
                    printf("check roundrobin id:%d %d(%d)\n",i,map[0], map[map[0]+2]);
                    if(skSer[i]!=map[map[0]+2]) continue;//if user roundrobin and this client haven't permision
                }else if(mode==2){//for increase time strategy (mode=2)
                    printf("check timeIncrease id:%d %d\n",i,tIDATA.clientControling);
                    if(i!=tIDATA.clientControling) continue;//if user roundrobin and this client haven't permision
                }
                //diagram of data: int cameranum,float centerRateX,float centerRateY,float rotate,float zoom
                memcpy(&cameranum,buf+sizeof(char)/sizeof(char),sizeof(int));
                memcpy(&centerRateX,buf+(sizeof(char)+sizeof(int))/sizeof(char),sizeof(float));
                memcpy(&centerRateY,buf+(sizeof(char)+sizeof(int)+sizeof(float)*1)/sizeof(char),sizeof(float));
                memcpy(&rotate,buf+(sizeof(char)+sizeof(int)+sizeof(float)*2)/sizeof(char),sizeof(float));
                memcpy(&zoom,buf+(sizeof(char)+sizeof(int)+sizeof(float)*3)/sizeof(char),sizeof(float));

                printf("%d %f %f %f %f\n",cameranum,centerRateX,centerRateY,rotate,zoom);
                addrequest(mode,cameraSock,i,cameranum,centerRateX,centerRateY,rotate,zoom);
                
                
            }else if(buf[0]==CAMERA_LIST_REQUEST){
                //save nick name of this client
                memcpy(skNickName+8*i,buf+1,8);
                //
                printf("CAMERA LIST REQUEST from %d(%c%c)-> send %d camera,size: %d %f\n",skSer[i],buf[1],buf[2],*(int*)(cameraInfo+1),cameraInfoLen,*(float*)(cameraInfo+1+sizeof(int)));
                if(mode==0){//if user roundrobin
                    updateRoundRobin(skSer[i]);
                }
                *(int*)(cameraInfo+sizeof(char)+sizeof(int)+sizeof(float)**(int*)(cameraInfo+sizeof(char)))=mode;
                *(int*)(cameraInfo+sizeof(char)+sizeof(int)*2+sizeof(float)**(int*)(cameraInfo+sizeof(char)))=default_time;
                *(int*)(cameraInfo+sizeof(char)+sizeof(int)*3+sizeof(float)**(int*)(cameraInfo+sizeof(char)))=max_time;
                *(float*)(cameraInfo+sizeof(char)+sizeof(int)*4+sizeof(float)**(int*)(cameraInfo+sizeof(char)))=alpha_time;
                write(skSer[i],cameraInfo,cameraInfoLen+sizeof(int)*2+sizeof(float));
                printf("%d %d\n",*(int*)(cameraInfo+sizeof(char)+sizeof(int)*2+sizeof(float)**(int*)(cameraInfo+sizeof(char))),*(int*)(cameraInfo+sizeof(char)+sizeof(int)*3+sizeof(float)**(int*)(cameraInfo+sizeof(char))));
                if(mode==0) write(skSer[i],"S",2);//if is roundrobin -> default send "Stop"
                //send list user to all user
                if(mode!= ROUND_ROBIN)sendListNameToClient();
                
            } else if(buf[0]==WANT_VIEW_CAMERA){
                int size=strlen(cameraIP);
                //if(cameraID>=0)printf("Request for IP of camera %s %d\n",cameraID,skSerIP[cameraID>=0?cameraID:0],size);
                memcpy(buf,&size,sizeof(int));
                memcpy(buf+sizeof(int),cameraIP,size);
                write(skSer[i],buf,sizeof(int)+size);
            }else if(buf[0]==WANT_CONTROL_CAMERA&&mode==TIME_INCREASE){
                tIDATA.requesting[i]=1;
                printf("Client %d want to control\n",skSer[i]);
            }else if(buf[0]==ESCAPE_CONTROL_CAMERA){
                tIDATA.requesting[i]=0;
                if(tIDATA.clientControling==i) tIDATA.clientControling=-1;
                printf("Client %d want to escape control\n",skSer[i]);                
                buf[0]='S';
                tmpTime=(tIDATA.clientTime)[i];
                printf("Sent time1:%f\n",tmpTime);
                memcpy(buf+1,&tmpTime,sizeof(float));
                write((tIDATA.ipClient)[i],buf,sizeof(char)+sizeof(float));
            }else if(buf[0]==SERVER_CONTROL_CLIENT){
                sockControlServerID=i;
                    printf("Change mode to %d\n",*(int*)(buf+1));
                    switch (*(int*)(buf+1)) {
                        case 0:
                            tmpFramePerSecond=*(int*)(buf+sizeof(char)+sizeof(int)*2);
                            if(numBytesRcvd>= (sizeof(char)+sizeof(int)*2)){
                                setRoundRobinMode(*(int*)(buf+sizeof(char)+sizeof(int)));
                            }
                            break;
                        case 1:
                            tmpFramePerSecond=*(int*)(buf+sizeof(char)+sizeof(int)+sizeof(float));
                            if(numBytesRcvd>= (sizeof(char)+sizeof(float)+sizeof(int))){
                                setWeightedMode(*(float*)(buf+sizeof(char)+sizeof(int)));
                            }
                            break;
                        case 2:
                            tmpFramePerSecond=*(int*)(buf+sizeof(char)+sizeof(int)*3+sizeof(float));
                            if(numBytesRcvd>=(sizeof(char)+sizeof(float)+sizeof(int)*3)){
                                setIncreaseTimeMode(*(int*)(buf+1+sizeof(int)),*(int*)(buf+1+sizeof(int)*2),*(float*)(buf+sizeof(char)+sizeof(int)*3));
                            }
                            break;
                        default:
                            perror("\n************\nInvail mode id\n************\n");
                            break;
                    }
                //send new FPS if modify
                if(tmpFramePerSecond!=framePerSecond){
                    printf("******** Update FPS %d to %d**********\n",framePerSecond,tmpFramePerSecond);
                    framePerSecond=tmpFramePerSecond;
                    buf[0]=SET_FPS;
                    *(int*)(buf+1)= framePerSecond;
                    write(cameraSock,buf,sizeof(int)+1);
                }
            }else if(buf[0]==CONTROL_MOTOR){
                printf("Motor control: %d %d\n",*(int*)(buf+1),*(int*)(buf+1+sizeof(int)));
                //end of send to all client
                if(mode==0){
                    printf("    check roundrobin id:%d %d(%d)\n",i,map[0], map[map[0]+2]);
                    if(skSer[i]!=map[map[0]+2]) continue;//if user roundrobin and this client haven't permision
                }else if(mode==2){//for increase time strategy (mode=2)
                    printf("    check timeIncrease id:%d %d\n",i,tIDATA.clientControling);
                    if(i!=tIDATA.clientControling) continue;//if user roundrobin and this client haven't permision
                }
                buf2[0]='H';
                buf2[1]=*(int*)(buf+1)+100;
                buf2[2]=*(int*)(buf+1+sizeof(int))+100;
                write(motorSock,buf2,3);
            }else if(buf[0]==MOTOR_CLIENT){
                motorSock=skSer[i];
                motorID=i;
            }
            
        }
    }

}