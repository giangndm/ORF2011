//
//  linkList.h
//  DragItemAround
//
//  Created by Minh Giang on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef struct _linkList{
    char* value;
    long long timeT;
    struct _linkList* next;
}List;

@interface linkList : NSObject{
    List* listSent;
    List* lastOb;
}
-(void) insert:(long long)time:(char*)value:(int)sizeV;
-(void) print;
-(void) clear;
-(List*) getList;
@end
