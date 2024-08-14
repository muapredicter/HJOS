#ifndef __LIB_KERNEL_LIST_H
#define __LIB_KERNEL_LIST_H
#include "global.h"

/**********   定义链表结点成员结构   ***********
 *结点中不需要数据成元,只要求前驱和后继结点指针*/
struct list_elem
{
    struct list_elem *prev; // 前躯结点
    struct list_elem *next; // 后继结点
};

/* 链表结构,用来管理整个队列 */
struct list
{
    /* head是队首,是固定不变的，不是第1个元素,第1个元素为head.next */
    struct list_elem head;
    /* tail是队尾,同样是固定不变的 */
    struct list_elem tail;
};

// 用于计算一个结构体成员在结构体中的偏移量
#define offset(struct_type, member_name) (int)(&(((struct_type *)0)->member_name))
// 用于通过一个结构体成员地址计算出整个结构体的起始地址
#define member_to_entry(struct_type, member_name, member_ptr) (struct_type *)((int)member_ptr - offset(struct_type, member_name))

typedef bool(function)(struct list_elem *, int arg);
void list_init (struct list*);
void list_insert_before(struct list_elem* before, struct list_elem* elem);
void list_push(struct list* plist, struct list_elem* elem);
void list_iterate(struct list* plist);
void list_append(struct list* plist, struct list_elem* elem);  
void list_remove(struct list_elem* pelem);
struct list_elem* list_pop(struct list* plist);
bool list_empty(struct list* plist);
uint32_t list_len(struct list* plist);
struct list_elem* list_traversal(struct list* plist, function func, int arg);
bool elem_find(struct list* plist, struct list_elem* obj_elem);

#endif
