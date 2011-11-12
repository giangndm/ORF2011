#include <stdio.h>
#include "dataprocess.h"
int main(){
    initGroup();
    addrequest(1,0,1,0,0.2,0.2,1,0.2);
    sleep(1);
    addrequest(1,0,1,0,0.38,0.38,0.77,0.2);
    sleep(1);
    addrequest(1,0,1,0,0.29,0.29,0.77,0.2);
    sleep(1);
    addrequest(1,0,2,1,0.5,0.5,1,1);
    sleep(1);
    addrequest(1,0,2,3,0.5,0.5,1,1);
    sleep(1);
}