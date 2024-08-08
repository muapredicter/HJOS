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
void list_init(struct list *list);
void list_insert(struct list *link, struct list *new_link);
void list_push(struct list *list, struct list *new_link);
void list_append(struct list *list, struct list *new_link);
void list_remove(struct list *link);
struct list *list_pop(struct list *list);
int list_find(struct list *list, struct list *link);
int list_empty(struct list *list);
uint32_t list_len(struct list *list);
struct list *list_traversal(struct list *list, function func, int arg);

#endif
