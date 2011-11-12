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
#define NUM_MAX_CLIENT 100
#define NUM_MAX_HOST 100
#define CAMERA_CLIENT 'C'
#define USER_CLIENT 'U'

/* 
 khai bao bien
 */
int len; 
char buf[1024];//using to get info of client and recv data from client
char *port="1412";
char pbuf[200];//store info port
int size,i,l;//using for loop
ssize_t numBytesRcvd;//size of Recv data from client/
struct addrinfo hints,*addrList,*a0;//using to get info of HOST to creat socket
struct sockaddr newSk_addr;//using to get info of client
int newSk_len,buf_len;
fd_set readfds,fdsSer;//using to create multi socket listten
int skSer[NUM_MAX_CLIENT];//array store socket of 
int skHost[NUM_MAX_HOST];
int newSK;
int numHost=0;
int cameraID;
char ipcamera[100];
/**/
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
        if(getnameinfo(a0->ai_addr,a0->ai_addrlen,buf,1024,pbuf,20,NI_NUMERICHOST|NI_NUMERICSERV)){//get name info of host and check if cannot!
            perror("Cannot get name info\n");
            sprintf(buf,"???");
            sprintf(pbuf,"???");
        }
        printf("%s %s %d\n",buf,pbuf,a0->ai_family);
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

int main(){
    int cameranum;
    float centerRateX,centerRateY,rotate,zoom;
    initSocket();
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
            if(getnameinfo(&newSk_addr,newSk_len,buf,1024,pbuf,20,NI_NUMERICHOST|NI_NUMERICSERV)){//get name info of new connect
                perror("Cannot get name info\n");
                sprintf(buf,"???");
                sprintf(pbuf,"???");
            }
            printf("Get connect form:%s %s\n",buf,pbuf);
            //
            for(i=0;i<NUM_MAX_CLIENT;i++) if(skSer[i]==0){//store socket of new connect
                skSer[i]=newSK;
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
                close(skSer[i]);
                skSer[i]=0;  
                
            }
            printf("Recv %d - %d size\n",numBytesRcvd,(sizeof(float)*4+sizeof(int)+sizeof(char)));
            if(buf[0]==CAMERA_CLIENT){//if client is camera -> setcamera client
                
                
            }else if(buf[0]==USER_CLIENT&&numBytesRcvd==(sizeof(float)*4+sizeof(int)+sizeof(char))){
                //diagram of data: int cameranum,float centerRateX,float centerRateY,float rotate,float zoom
                memcpy(&cameranum,buf+sizeof(char)/sizeof(char),sizeof(int));
                memcpy(&centerRateX,buf+(sizeof(char)+sizeof(float))/sizeof(char),sizeof(float));
                memcpy(&centerRateY,buf+(sizeof(char)+sizeof(float)*2)/sizeof(char),sizeof(float));
                memcpy(&rotate,buf+(sizeof(char)+sizeof(float)*3)/sizeof(char),sizeof(float));
                memcpy(&zoom,buf+(sizeof(char)+sizeof(float)*4)/sizeof(char),sizeof(float));
                printf("%d %f %f %f %f\n",cameranum,centerRateX,centerRateY,rotate,zoom);
            }
            
        }
    }

}