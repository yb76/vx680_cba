/*
**-----------------------------------------------------------------------------
** PROJECT:			iRIS
**
** FILE NAME:       realloc.c
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

#ifdef __MY_MALLOC
static void * iris_realloc(void * ptr, unsigned int size, void * start_range, void * end_range, unsigned int block_size)
{
	if (ptr >= start_range && ptr < end_range)
	{
		if (size <= block_size)
			return ptr;
		else
		{
			void * ptr2;

			ptr2 = my_malloc(size);
			if (ptr2)
			{
				memcpy(ptr2, ptr, block_size);
				my_free(ptr);
			}

			return ptr2;
		}
	}

	return NULL;
}
#endif

void * my_realloc(void * ptr, unsigned int size)
{
#ifdef __MY_MALLOC
	void * new_ptr;

	if (size/4*4 != size)
		size = size/4*4 + 4;

	// Check the iris tiny heap first
	new_ptr = iris_realloc(ptr, size, iris_tiny_heap, &iris_tiny_heap[C_MAX_TINY_BLOCKS], C_TINY_BLOCK_SIZE);
	if (new_ptr) return new_ptr;

	// Check the iris medium heap second
	new_ptr = iris_realloc(ptr, size, iris_med_heap, &iris_med_heap[C_MAX_MED_BLOCKS], C_MED_BLOCK_SIZE);
	if (new_ptr) return new_ptr;

	// Check the iris big heap third
	new_ptr = iris_realloc(ptr, size, iris_big_heap, &iris_big_heap[C_MAX_BIG_BLOCKS], C_BIG_BLOCK_SIZE);
	if (new_ptr) return new_ptr;
#endif

	return realloc(ptr, size);
}

