//
//  linkList.m
//  DragItemAround
//
//  Created by Minh Giang on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "linkList.h"

@implementation linkList

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        listSent= NULL;
    }
    
    return self;
}
-(void) insert:(long long)timeT:(char*)value:(int)sizeV{
    if(listSent==NULL){
        listSent= (List*)malloc(sizeof(List));
        lastOb=listSent;
    }else{
        lastOb->next=(List*)malloc(sizeof(List));
        lastOb=lastOb->next;
    }
    lastOb->next=NULL;
    lastOb->timeT=timeT;
    
    lastOb->value= (char*)malloc(sizeof(char)*sizeV);
    memcpy(lastOb->value, value,sizeV);
    printf("Insert %lld %p\n",timeT,lastOb);
}
-(void) clear{
    List* tmp= listSent;
    List* tmp2;
    while(tmp!=NULL){
        tmp2=tmp;
        tmp=tmp->next;
        free(tmp2->value);
        free(tmp2
             
             
             
             
             
             
             
             
             
             
             );
    }
    listSent=NULL;
}
- (void) print{
    List* tmp=listSent;
    while(tmp!=NULL){
        printf("%lld %s\n",tmp->timeT,tmp->value);
        tmp=tmp->next;
    }
}
-(List*) getList{
    return listSent;
}
@end
