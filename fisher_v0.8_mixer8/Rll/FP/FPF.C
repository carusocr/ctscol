/*!----------------------------------------------------------------------------

      Module:	Floating Point Runtime Link Library Functions

    Filename:	FPF.C

 Description:	This module implements all of the floating point functions
		for the FP.DLL runtime link library

      Author:	S. W. Lange

        Date:	04-23-93 : 08:32:12am

*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -!*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <math.h>
#include <windows.h>
#include "ntrll.h"

//------------------------ Defines And Static Variables ------------------------

#define CVTBUFSIZE	349	/*  Microsoft C internal constant  */
#define INTARG(n)	atoi(argv[(n)])
#define FLOATARG(n)	atof(argv[(n)])
#define TRUNCATE	0
#define ROUND_UP	1
#define ROUND_UP_DOWN	2
#define LARGE_ERROR	"99999999999999999999"

#define DSTRLEN 	512
typedef char DSTRING[DSTRLEN+1];

static int iDecs;			// Decimal places
static DSTRING dszResult;		// Buffer to hold return value
static double dValue, dDenom;

//-------------------------- Function Prototypes -------------------------------

/*
 * Undocumented Microsoft function to format floating point values as 
 * strings with an arbitrary number of decimal places.
 */

char *_cftof(double *, char *, int);

//------------------------------------------------------------------------------

// Called when VOS loads RLL
t_func fpStart(void)
	{
	iDecs = 2;
	voslog("VOS/NT Fixed Point RLL (rev %s) loaded", __DATE__);
	return "";
	}

//------------------------------------------------------------------------------

// fp_decs(places):	Set the number of places after the decimal point

t_func fp_decs(int argc, char **argv)
	{
	iDecs = INTARG(0);
	sprintf(dszResult, "%d", iDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_add(num1, num2, places)
 *	Add two numbers with optional number of places after 
 *	decimal point.
 */
 
t_func fp_add(int argc, char **argv)
	{
	int iTmpDecs = argc == 3 ? INTARG(2) : iDecs;

	dValue = FLOATARG(0) + FLOATARG(1);
	_cftof(&dValue, dszResult, iTmpDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_sub(num1, num2, places)
 *	Subtract two numbers with optional number of places after 
 *	decimal point.
 */
 
t_func fp_sub(int argc, char **argv)
	{
	int iTmpDecs = argc == 3 ? INTARG(2) : iDecs;

	dValue = FLOATARG(0) - FLOATARG(1);
	_cftof(&dValue, dszResult, iTmpDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_mul(num1, num2, places)
 *	Multiply two numbers with optional number of places after 
 *	decimal point.
 */
 
t_func fp_mul(int argc, char **argv)
	{
	int iTmpDecs = argc == 3 ? INTARG(2) : iDecs;

	dValue = FLOATARG(0) * FLOATARG(1);
	_cftof(&dValue, dszResult, iTmpDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_div(numerator, denominator, places)
 *	Divide two numbers with optional number of places after the 
 *	decimal point.
 */
 
t_func fp_div(int argc, char **argv)
	{
	int iTmpDecs = argc == 3 ? INTARG(2) : iDecs;

	dDenom = FLOATARG(1);
	if(dDenom == 0.0)
		{
		voslog("@E fp_div(%s, %s):  Divide overflow", argv[0], argv[1]);
		return LARGE_ERROR;
		}

	dValue = FLOATARG(0) / dDenom;
	_cftof(&dValue, dszResult, iTmpDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_pow(number, exponent, places)
 *	Raise a number to an exponent with an optional number of places 
 *	after the decimal point.  This function accepts positive and 
 *	negative floating point numbers for the number and exponent 
 *	arguments.  If the number is negative, the exponent must be a 
 *	whole number, else an error will result.
 *
 * Returns:
 *	0.0 on error, else the number raised to the exponent power.
 */

t_func fp_pow(int argc, char **argv)
	{
	int iTmpDecs = argc == 3 ? INTARG(2) : iDecs;

	dValue = pow(FLOATARG(0), FLOATARG(1));
	if(errno != 0 || dValue == HUGE_VAL)
		dValue = 0.0;
	_cftof(&dValue, dszResult, iTmpDecs);
	return dszResult;
	}

//------------------------------------------------------------------------------

/*
 * fp_rnd(number, type, position, places)
 *	Truncate or round up or down according to the value of the type
 *	passed in:
 *		type	= 0 --> Truncate
 *			= 1 --> Round up
 *			= 2 --> Round down if number < xxx5 else round up
 *	Round starting at position.  Examples:
 *		fp_rnd(6535000, 6, 1) = 6600000
 *		fp_rnd(35627, 3, 0) = 35600
 *		fp_rnd(268, 2, 2) = 300
 *		fp_rnd(1215.3478, -2, 3) = 1215.350
 *	Format number with optional number of places after the decimal point.
 */

t_func fp_rnd(int argc, char **argv)
	{
	double number = FLOATARG(0);
	int type = INTARG(1), position = INTARG(2);
	int i, iTmpDecs = argc == 4 ? INTARG(3) : iDecs;
	double num_floor;

	if(position >= 0)
		for(i=1; i<=position; i++)
			number /= 10;
	else
		for(i=1; i<=(-position); i++)
			number *= 10;

	switch(type) {
		case TRUNCATE:
			number = number < 0 ? ceil(number) : floor(number);
			break;

		case ROUND_UP:
			number = number < 0 ? floor(number) : ceil(number);
			break;

		case ROUND_UP_DOWN:
			num_floor = floor(number);
			number = (number - num_floor < 0.5) ? num_floor : num_floor + 1;
			break;
		default:
			number = 0;
			break;
	} // End switch(type)

	if(position >= 0)
		for(i=1; i<=position; i++)
			number *= 10;
	else
		for(i=1; i<=(-position); i++)
			number /= 10;

	// Format the floating point number as a string and return

	_cftof(&number, dszResult, iTmpDecs);
	return dszResult;
	} // End fp_rnd()

//------------------------------------------------------------------------------
