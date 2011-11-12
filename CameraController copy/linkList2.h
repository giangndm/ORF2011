//
//  linkList2.h
//  DragItemAround
//
//  Created by Minh Giang on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef struct _linkList2{
    double x,y;
    struct _linkList2* next;
}List2;

@interface linkList2 : NSObject{
    double minX,minY;
    List2* List2Sent;
    List2* lastOb;
    Boolean isLock;
    int sizeL;
}
-(void) insert:(double)x:(double)y;
-(void) print;
-(void) clear;
-(int) getSize;
-(List2*) getList2;
-(double*) getNomalArray:(int)size;
@end
