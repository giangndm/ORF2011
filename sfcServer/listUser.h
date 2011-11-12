#include <stdio.h>
#include <stdlib.h>
typedef struct _nodeUser{
    int uSock;
    //for last controler
    struct _nodeUser* next;
}nodeUser;
typedef struct _listUser{
    nodeUser* first;
    nodeUser* last;
}listUser;
listUser* initList(){
    listUser* list= (listUser*)malloc(sizeof(listUser));
    list->first=NULL;
    list->last=NULL;
    return list;
}
void insert(listUser* list,int sock){
    if(list->first==NULL){
        list->first=(nodeUser*)malloc(sizeof(nodeUser));
        list->last=list->first;
        list->first->next=0;
        list->first->uSock=sock;
    }else{
        list->last->next=(nodeUser*)malloc(sizeof(nodeUser));
    }
}