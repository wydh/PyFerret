	SUBROUTINE TM_PURGE_TMP_GRIDS( status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 

* This routine is normally called only for error conditions that occur
* in the midst of building grids and axes for netCDF files.
* The goal is to throw away all of the in-progress work on grids and
* axes, including allocations (use count increments) of axes that came
* from other data sets.

* major re-write 2/2016:
* As it was, this routine could accidentally attempt to remove tmp
*    lines twice by making a call to deallo line and then a call to deallo
*    one or more grids that used that line.
* It became two difficult to keep track of the dependencies when error occured
*    during the definition of aggregate Ferret datasets.
* The new version of this routine simply clears out the tmp lines and axes.
* If any of the tmp grid used axes from pre-existing datasets AND THE USE
* COUNTS FOR THOSE AXES HAD ALREADY BEEN BUMBED BEFORE THIS ROUTINE WAS CALLED
* then this routine could now result in a minor corruption (an axis that will
* never get deleted.)
* Possible corruption risk for legacy GT or MC datasets?
* SHOW GRID/DYNAMIC diagnositcs should reveal the corruption.


* Steve Hankin  NOAA/PMEL/TMAP

* V510 *sh* 3/00
* V674 2/12 *acm* 6D Ferret: use nferdims rather than 4 for dimension indexing
* V697 12/15 *acm* Ticket 2332: deallo lines should not be in a 1:nferdims loop
* V698 2/16 *sh*  major rewrite -- see discussion above
 
* Include files
	include 'tmap_dims.parm'
	include 'tmap_errors.parm'
#include "gt_lib.parm"
        include 'xtm_grid.cmn_text'
        include 'xio.cmn_text'
#include "tmap_dset.parm"

* Argument definitions
	INTEGER status

* Local variable declarations
	INTEGER grid, line, idim

* remove temporary grids
 100	CONTINUE
	   grid = 0	! to get start of list
	   CALL TM_NEXT_TMP_GRID(grid, *300)

	   CALL TM_RM_TMP_GRID(grid)

	GOTO 100

* remove temporary lines
 300	CONTINUE
	   line = 0		! to get start of list
 	   CALL TM_NEXT_TMP_LINE(line, *1000)

	   CALL TM_RM_TMP_LINE(line)

	GOTO 300

* successful completion
 1000	status = merr_ok	! always as of 2/2016
	RETURN

 	END
