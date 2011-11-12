//
//  fileFunc.h
//  DragItemAround
//
//  Created by Minh Giang on 9/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface fileFunc : NSObject{
    char* fileN,*modeN;
    FILE* f;
    double* rtArr[40];
    double* rtIDArr;
    double* idArr;
    int numLine;
}
-(void)open:(char*) filename:(char*) mode;
-(void)write:(int)code:(double*)data:(int)size;
-(void)reload;
-(void)readFile;
-(void)deleteID:(int)idGesture;
-(double**)getLearnData;
-(double*)getIDarr;
-(int)getNumData;
@end
