//
//  softmax.m
//  DragItemAround
//
//  Created by Minh Giang on 9/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "softmax.h"

@implementation softmax

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        X=NULL;
        O=NULL;
        
        Y=NULL;
        X2=NULL;
    }
    
    return self;
}
-(void) printO{
    int i,j;
    for(i=0;i<k;i++){
        for(j=0;j<n;j++) printf("%f ",(O[i][j]-delta));
        printf("\n");
    }
        printf("-----------------\n");
}
-(double)Ex:(int) Oj:(int) Xi{
    int i;
    double sum=0;
    for(i=0;i<n;i++)
        sum+=(O[Oj][i]-delta)*X[i][Xi];
    //System.out.println("	Sum at Oj="+Oj+" Xi="+Xi+"="+sum);
    return exp(sum);
    
}
-(double) calcSum:(int) Xi{
    int l;
    double sum=0;
    for(l=0;l<k;l++){
        sum+=[self Ex:l:Xi];
    }
    //System.out.println("CalcSum at Xi="+Xi+"="+sum);
    return sum;
}
-(void) checkNaN{
    int Cexit=1;
    int i,j,l;
    while(true){
        Cexit=1;
        for(i=0;i<m;i++)if(isnan([self calcSum:i])) {
            //System.out.println("IsNan");
            //System.in.read();
            for(j=0;j<k;j++)
                for(l=0;l<n;l++) O[j][l]+=1;
            Cexit=0;
        }
        if(Cexit==1){
//            System.out.println("Exit NaN");
            break;
        }
    }
}
-(double) P:(int) Xi:(int) Oj{
    double p=[self Ex:Oj:Xi]/[self calcSum:Xi ];
    //System.out.println("P("+Xi+","+Oj+")="+p);
    return p;
}
-(double*) deltaJO:(int) Oj{
    double* sum= NULL;
    sum= (double*)malloc(sizeof(double)*n);
    
    double pTmp;
    int j,i;
    //System.out.println("Update2 "+Oj);
    for(j=0;j<n;j++) sum[j]=0;
    for(i=0;i<m;i++){
        //System.out.println("Update step "+i);
        if(Y[i]==Oj){
            pTmp=1-[self P:i:Oj];
            //System.out.println("	P=1-P(i,Oj)= "+pTmp);
        }else{
            pTmp= 0-[self P:i:Oj];
            //System.out.println("	P=-P(i,Oj)= "+pTmp);
        }
        for(j=0;j<n;j++) {
            //System.out.print("  **UpdateSum["+j+"]="+sum[j]+"+"+pTmp+"*"+X[j][i]+"="+sum[j]);
            sum[j]+=pTmp*X[j][i];
            //System.out.println(" ="+sum[j]);
        }
    }
    for(j=0;j<n;j++){
        //System.out.println("Before Sum[j]="+sum[j]/m+"/"+m);
        sum[j]=-1*sum[j]/m;
        //System.out.println("After Sum[j]="+sum[j]);
        //change O
        //System.out.print("O["+Oj+"]["+j+"]="+O[Oj][j]+"-"+alpha+"*"+sum[j]);
        O[Oj][j]-=alpha*sum[j];
        //System.out.println("="+O[Oj][j]);
        //
    }
    return sum;
}
-(double) update{
    //[self printO];
    double* sum;
    double argSum=0.0;
    int i,j;
    [self checkNaN];
    for(i=0;i<k;i++){
        //System.out.print("Update "+i);
        sum=[self deltaJO:i];
        for(j=0;j<n;j++){
            //System.out.print(sum[j]+" ");
            argSum+=sum[j]*sum[j];
        }
    }
    argSum/=(n*k);
    printf("**********SumErr=%1.20lf***********\n",argSum);
    return argSum;
}
/*predic*/
-(double) Ex2:(int) Oj:(int) Xi{
    int i;
    double sum=0;
    for(i=0;i<n;i++)
        sum+=(O[Oj][i]-delta)*X2[i][Xi];
    //System.out.println("	Sum at Oj="+Oj+" Xi="+Xi+"="+sum);
    return exp(sum);
}
-(double) calcSum2:(int) Xi{
    int l;
    double sum=0;
    for(l=0;l<k;l++){
        sum+=[self Ex2:l:Xi];
    }
    //System.out.println("CalcSum at Xi="+Xi+"="+sum);
    return sum;
}
-(double) P2:(int) Xi:(int) Oj{
    //printf("Xi=%d Oj=%d\n",Xi,Oj);
    double p=[self Ex2:Oj:Xi]/[self calcSum2:Xi];
    //System.out.println("P("+Xi+","+Oj+")="+p);
    return p;
}
-(int) predic2:(double*) X2t:(double*)present{
    int preDict=0,j;
    double max=0;
    m2=1;
    if(X2==NULL) X2=(double**) malloc(sizeof(double*));
    
    X2[0]=X2t;
    for(j=0;j< k;j++){
        if(max<[self P2:0:j ]){
            max=[self P2:0:j ];
            preDict=j;
        }
    }
    *present=max;
    return preDict;
}
-(int) predic:(double**) X2t:(int) m2t:(double*) Y2t{
    X2=X2t;
    m2=m2t;
    //printO();
    int preDict=0,i,j;
    double max=0;
    int count=0;
    int count1=0,count0=0,m0=0,m1=0;
    for(i=0;i<m2;i++){
        preDict=0;
        max=0;
        //System.out.println();
        for(j=0;j< k;j++){
            if(max<[self P2:i:j ]){
                max=[self P2:i:j ];
                preDict=j;
            }
            //System.out.print(P2(i,j)+" ");
            
        }
        
//        System.out.println("\n"+preDict+"+"+Y2[i]);
        if(preDict==0) m0++; else m1++;
        if(preDict-Y2t[i]>-0.1&&preDict-Y2t[i]<0.1) {
            count++;
            if(preDict==0) count0++;
            else count1++;
//            System.out.println("**");
        }
    }
   // System.out.println(m0+" "+m1+" "+count*1.0/m2);
    return 0;
}
/**
 X la mang hoc, Y la gia tri, k la so gia tri khac nhau, m1 la so luong vector, n la chieu dai 1 vector
 alpha la he so hoc
 **/
-(void) saveMatrix:(char*)fileName{
    FILE* f= fopen(fileName, "wb++");
    int i,j;
    fwrite(&delta, sizeof(delta), 1, f);
    fwrite(&k, sizeof(k), 1, f);
    fwrite(&n, sizeof(n), 1, f);
    for(i=0;i<k;i++){ 
        //O[i]=(double*)malloc(sizeof(double)*n1);
        fwrite(O[i], sizeof(double), n, f);
        for(j=0;j<n;j++)printf("%f ",O[i][j]);
    }
    fclose(f);
}
-(void) softmaxLoadFile:(char*)fileName{
    FILE* f= fopen(fileName, "rb++");
    int i,j;
    if(f==NULL||feof(f))return;
    fread(&delta, sizeof(delta), 1, f);
    fread(&k, sizeof(k), 1, f);
    fread(&n, sizeof(n), 1, f);
    printf("delta=%f k=%d n=%d\n",delta,k,n);
    O= (double**)(malloc(sizeof(double*)*k));//double[k][n];
    for(i=0;i<k;i++){ 
        O[i]=(double*)malloc(sizeof(double)*n);
        fread(O[i], n, sizeof(double), f);
        printf("\n*****");
        for(j=0;j<n;j++)printf("%f ",O[i][j]);
    }
    X2=NULL;
    fclose(f);
}
//in this: k1 is number of clastify, m1 is
-(void) softmax:(int) k1:(int) n1{
    delta=10;
    k= k1;
    O= (double**)(malloc(sizeof(double*)*k));//double[k][n];
        int i,j;
    for(i=0;i<k;i++){ 
        O[i]=(double*)malloc(sizeof(double)*n1);
        
        for(j=0;j<n1;j++)O[i][j]=0;
    }
    n=n1;
    X2=NULL;

}
-(int)test:(double*) X2t:(double*)present{
    int preDict=0,j;
    double max=0;
    m2=1;
    if(X2==NULL){ 
        //printf("setnew X2\n");
        X2=(double**) malloc(sizeof(double*)*n);

        for(j=0;j<n;j++){ 
            X2[j]=(double*)malloc(sizeof(double)*2);
            
        }
    }
    for(j=0;j<n;j++){ X2[j][0]=X2t[j];}
    
    //for(j=0;j<40;j++) printf("%lf ",X2[0][j]);
    for(j=0;j< k;j++){
        if(max<[self P2:0:j ]){
            *present=[self P2:0:j ]-max;
            max=[self P2:0:j ];
            preDict=j;
        }
    }
    return preDict;
}
-(void) training:(double**) X1:(double*) Y1:(int)m1:(double) alpha1:(double)maxErr:(int)numUpdate{
    X= X1;
    Y= Y1;
    alpha=alpha1;
    m=m1;
    int l;
    printf("%d %d\n",numUpdate,k);
    for(l=0;l<numUpdate||numUpdate==-1;l++){
        if([self update]<maxErr) break;
        printf("Softmax:%f\n",l*100.0/numUpdate);
    }

}
@end
