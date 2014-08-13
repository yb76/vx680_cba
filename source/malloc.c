/*
**-----------------------------------------------------------------------------
** PROJECT:			iRIS
**
** FILE NAME:       malloc.c
**
** DATE CREATED:    30 January 2008
**
** AUTHOR:          Tareq Hafez
**
** DESCRIPTION:     Allocates on a 4-byte boundry
**-----------------------------------------------------------------------------
*/

//
//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------
//

//
// Standard include files.
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//
// Project include files.
//

/*
** Local include files
*/
#include "alloc.h"

#ifdef __MY_MALLOC
T_TINY_HEAP iris_tiny_heap[C_MAX_TINY_BLOCKS];
T_TINY_HEAP * iris_tiny_heap_head;

T_MED_HEAP iris_med_heap[C_MAX_MED_BLOCKS];
T_MED_HEAP * iris_med_heap_head;

T_BIG_HEAP iris_big_heap[C_MAX_BIG_BLOCKS];
int iris_big_heap_used[C_MAX_BIG_BLOCKS];

int tiny_counter = 0;
int max_tiny_counter = 0;

int med_counter = 0;
int max_med_counter = 0;

int big_counter = 0;
int max_big_counter = 0;
#endif

/*
**-----------------------------------------------------------------------------
** Constants
**-----------------------------------------------------------------------------
*/


/*
**-----------------------------------------------------------------------------
** Module variable definitions and initialisations.
**-----------------------------------------------------------------------------
*/

void * my_malloc(unsigned int size)
{
#ifdef __MY_MALLOC
	void ** ptr;

	if (size/4*4 != size)
		size = size/4*4 + 4;

	// Initialise if required
	if (iris_tiny_heap_head == NULL)
	{
		int i = 0;

		iris_tiny_heap_head = iris_tiny_heap;
		for (i = 0; i < (C_MAX_TINY_BLOCKS - 1); i++)
			iris_tiny_heap[i].block[0] = &iris_tiny_heap[i+1];

		iris_med_heap_head = iris_med_heap;
		for (i = 0; i < (C_MAX_MED_BLOCKS - 1); i++)
			iris_med_heap[i].block[0] = &iris_med_heap[i+1];
	}

	if (size <= C_TINY_BLOCK_SIZE && (ptr = iris_tiny_heap_head->block) != NULL)
	{
		iris_tiny_heap_head = ptr[0];
		tiny_counter++;
		if (tiny_counter > max_tiny_counter) max_tiny_counter = tiny_counter;
		return (void *) ptr;
	}	
	else if (size <= C_MED_BLOCK_SIZE && (ptr = iris_med_heap_head->block) != NULL)
	{
		iris_med_heap_head = ptr[0];
		med_counter++;
		if (med_counter > max_med_counter) max_med_counter = med_counter;
		return (void *) ptr;
	}	
	else if (size <= C_BIG_BLOCK_SIZE)
	{
		int i;

		for (i = 0; i < C_MAX_BIG_BLOCKS; i++)
		{
			if (!iris_big_heap_used[i])
			{
				iris_big_heap_used[i] = 1;
				big_counter++;
				if (big_counter > max_big_counter) max_big_counter = big_counter;
				return iris_big_heap[i].block;
			}
		}
	}
#endif

	return malloc(size);
}

void my_free(void * block)
{
#ifdef __MY_MALLOC
	if (block >= (void *) iris_tiny_heap && block < (void *) &iris_tiny_heap[C_MAX_TINY_BLOCKS])
	{
		tiny_counter--;
		((void **)block)[0] = iris_tiny_heap_head;
		iris_tiny_heap_head = block;
	}
	else if (block >= (void *) iris_med_heap && block < (void *) &iris_med_heap[C_MAX_MED_BLOCKS])
	{
		med_counter--;
		((void **)block)[0] = iris_med_heap_head;
		iris_med_heap_head = block;
	}
	else
	{
		int i;

		for (i = 0; i < C_MAX_BIG_BLOCKS; i++)
		{
			if (iris_big_heap[i].block == block)
			{
				iris_big_heap_used[i] = 0;
				big_counter--;
				return;
			}
		}
		
		if (block) free(block);
	}
#else
	if (block) free(block);
#endif
}
