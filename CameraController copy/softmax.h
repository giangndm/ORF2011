//
//  softmax.h
//  DragItemAround
//
//  Created by Minh Giang on 9/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
@interface softmax : NSObject{
    double **X,**O,deltaO,tmp;
	double* Y;
	double** X2;
	int k,m,n,m2;
	double alpha;
	double delta;
    
}
-(double) update;
-(int) predic2:(double*) X2t:(double*)present;
-(void) softmax:(int) k1:(int) n1;
-(int)test:(double*) X2t:(double*)present;
-(int) predic:(double**) X2t:(int) m2t:(double*) Y2t;
-(void) saveMatrix:(char*)fileName;
-(void) softmaxLoadFile:(char*)fileName;
-(void) training:(double**) X1:(double*) Y1:(int)m1:(double) alpha1:(double)maxErr:(int)numUpdate;
@end
