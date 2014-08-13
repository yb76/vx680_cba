/*
**-----------------------------------------------------------------------------
** PROJECT:			iRIS
**
** FILE NAME:       calloc.c
**
** DATE CREATED:    30 January 2008
**
** AUTHOR:          Tareq Hafez
**
** DESCRIPTION:     Allocates on a 4 byte boundry
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

void * my_calloc(unsigned int size)
{
#ifdef __MY_MALLOC
	void * ptr = my_malloc(size);

	if (ptr)
		memset(ptr, 0, size);

	return ptr;
#else
	return(calloc(size,sizeof(void*)));
#endif

//	if (size/4*4 != size)
//		size = size/4*4 + 4;
//	return calloc(1, size);
}
