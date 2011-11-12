//
//  fileFunc.m
//  DragItemAround
//
//  Created by Minh Giang on 9/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "fileFunc.h"

@implementation fileFunc

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        f=NULL;
    }
    
    return self;
}
-(void)open:(char*) filename:(char*) mode{

    fileN=strdup(filename);
    //printf("%s\n",fileN);
    modeN=strdup(mode);
    //if(f!=NULL) fclose(f);
    //f= fopen(filename, mode);
    //fprintf(f,"aaaa");
    //FILE * f2= fopen("/DATA/data2.txt","w+");
    //fprintf(f2,"aaa");
    //fclose(f2);
}
-(void)write:(int)code:(double*)data:(int)size{
    int i;
    f=fopen(fileN, "a++");
    if(f==NULL)f=fopen(fileN, "w++");
    printf("f");
    fprintf(f,"%d:",code);
    for(i=0;i<size;i++) fprintf(f, "%lf ",data[i]);
    fprintf(f,"\n");
    fclose(f);
}
-(void)reload{
    fclose(f);
    f= fopen(fileN, modeN);
}
-(void)readFile{
    char buf[2000];
    int i=0,j;
    i=0;j=0;
    numLine=-1;

    f= fopen(fileN, "r+");
    if(f==NULL){
        printf("Notfound file\n");
        f= fopen(fileN, "w+");
        fclose(f);
        return;
    }
    /*count number line*/
    while(!feof(f)){
        fgets(buf, 2000, f);
        numLine++;
    }
    printf("%d\n",numLine);
    for(j=0;j<40;j++){
        //printf("Maloc %d\n",j);
        rtArr[j]=(double*)malloc(sizeof(double)*numLine);
    }
    rtIDArr=(double*)malloc(sizeof(double)*numLine);
    //printf("File have %d line %p %p\n",numLine,rtIDArr,rtArr);
    fseek(f, 0, 0);
    while(!feof(f)&&i<numLine) {
        fscanf(f,"%lf:",rtIDArr+i);
        
        if(feof(f)) break;
        //printf("%1.0lf:",*((*idArr)+i));
        for(j=0;j<40;j++){
            fscanf(f,"%lf",rtArr[j]+i);
            printf("%f ",rtArr[j][i]);
        }
        printf("a\n");
        i++;
    }
    
    fclose(f);
}
-(void)deleteID:(int)idGesture{
    [self readFile];
    int i,j;
    f=fopen(fileN,"w++");
    for(i=0;i<numLine;i++){
        if((int)rtIDArr[i]!=idGesture){
            fprintf(f,"%d:",(int)rtIDArr[i]);
            for(j=0;j<40;j++) fprintf(f, "%lf ",rtArr[j][i]);
            fprintf(f,"\n");
        }
    }
    fclose(f);
}
-(double**)getLearnData{
    return rtArr;
}
-(double*)getIDarr{
    return  rtIDArr;
}
-(int)getNumData{
    return numLine;
}
@end
