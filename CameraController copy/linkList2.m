//
//  linkList2.m
//  DragItemAround
//
//  Created by Minh Giang on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "linkList2.h"

@implementation linkList2

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        List2Sent= NULL;
        sizeL=0;
        minX=2;
        minY=2;
        isLock=false;
    }
    
    return self;
}
-(void) insert:(double)x:(double)y{
    if(isLock)return;
    if(List2Sent==NULL){
        List2Sent= (List2*)malloc(sizeof(List2));
        lastOb=List2Sent;
    }else{
        lastOb->next=(List2*)malloc(sizeof(List2));
        lastOb=lastOb->next;
    }
    lastOb->next=NULL;
    lastOb->x=x;
    lastOb->y=y;
    if(minX>x)minX=x;
    if(minY>y)minY=y;
    sizeL++;
    //printf("Insert %lld %p\n",timeT,lastOb);
}
-(void) clear{
    isLock=true;
    List2* tmp= List2Sent;
    List2* tmp2;
    while(tmp!=NULL){
        tmp2=tmp;
        tmp=tmp->next;
        free(tmp2);
    }
    List2Sent=NULL;
    sizeL=0;
    minX=2;
    minY=2;
    isLock=false;
}
- (void) print{
    List2* tmp=List2Sent;
    printf("Begin Print");
    while(tmp!=NULL){
        printf("%f\n",tmp->x);
        tmp=tmp->next;
    }
}
-(List2*) getList2{
    return List2Sent;
}
static double* rtArray=NULL;
static double* rtArray2=NULL;
-(double*) getNomalArray:(int)size{
    id savedException = nil;
    if(isLock)return NULL;
    isLock=true;
    @try {
        if(!rtArray)rtArray=(double*)malloc(sizeof(double)*size*2);
        if(!rtArray2)rtArray2=(double*)malloc(sizeof(double)*size);
        int i,count=0;
        List2* tmp=List2Sent;
        for(i=0;i<size;i++) rtArray[i]=rtArray2[i]=-1;
        for(i=0,count=0;tmp!=NULL;tmp=tmp->next,i++){//count use for rtArray index
            tmp->x-=minX;
            tmp->y-=minY;
            //if(count<0) break;
            /* for back point**/
            for(count=(int)(i*1.0/(sizeL-1)*(size-1));(int)(count*1.0/(size-1)*(sizeL-1))>=i-1&&count>=0;count--){
                //if(count<0||count>=size) break;
                if(rtArray[count]<0){
                    rtArray[count]=(double)(1-(i-count*1.0/(size-1)*(sizeL-1)))*tmp->x;
                    rtArray2[count]=(double)(1-(i-count*1.0/(size-1)*(sizeL-1)))*tmp->y;
                }else{
                    rtArray[count]+=(double)(1-(i-count*1.0/(size-1)*(sizeL-1)))*tmp->x;
                    rtArray2[count]+=(double)(1-(i-count*1.0/(size-1)*(sizeL-1)))*tmp->y;
                }
            }
            //if(count<0) break;
            /* for back point**/
            for(count=(int)(i*1.0/(sizeL-1)*(size-1))+1;(int)(count*1.0/(size-1)*(sizeL-1))==i&&count<size;count++){
                //if(count<0||count>=size) break;
                if(rtArray[count]<0){
                    rtArray[count]=(double)(1+(i-count*1.0/(size-1)*(sizeL-1)))*tmp->x;
                    rtArray2[count]=(double)(1+(i-count*1.0/(size-1)*(sizeL-1)))*tmp->y;
                }else{
                    rtArray[count]+=(double)(1+(i-count*1.0/(size-1)*(sizeL-1)))*tmp->x;
                    rtArray2[count]+=(double)(1+(i-count*1.0/(size-1)*(sizeL-1)))*tmp->y;
                }
                
            }
        }
        for(i=0;i<size;i++){
            rtArray[i+size]=rtArray2[i];
        }

    }
    @catch (NSException *exception) {
        savedException = [exception retain];
        return NULL;
        @throw;
    }
    @finally {
        [savedException autorelease];
        return rtArray;
    }

}
-(int) getSize{
    return sizeL;
}
@end
