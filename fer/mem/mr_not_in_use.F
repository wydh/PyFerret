	SUBROUTINE MR_NOT_IN_USE ( mr )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
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
*
*
* release one claim of being required for calculations from variable mr
* if this release leaves the variable unneeded for any calculations then return
* it to the deletable variable chain

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  6/12/89
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
*        12/16 *sh* Bug fix - check if already *in* delete chain before adding
*		added diagnostic sanity checks
* V702: *sh* 1/17 issue error message on inappropriate calls to this routine
*		  immediate return on protected variables
*                 (have LOAD/TEMP code in XEQ_LOAD to remove permanance)

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'errmsg.parm'
	include 'xvariables.cmn'

* calling argument declarations:
	INTEGER mr

* internal variable declarations:
	INTEGER last_head, status


	IF ( mr_protected(mr) .GT. mr_not_protected ) THEN
	   mr_protected(mr) = mr_protected(mr) - 1
* ... if no one needs this variable any longer it is no longer "essential"
	   IF ( mr_protected(mr) .EQ. mr_not_protected ) THEN
	      essential_mem = essential_mem - mr_size(mr)
	   ENDIF

	ELSEIF ( mr_protected(mr) .LT. mr_not_protected ) THEN
* ... mr_temporary variables can end up here during immediate mode evaluations
*     see the list of possible mr_* states in ferret.parm
	   RETURN

	ELSE
* ... over-freeing of the mr -- should never happen
	   CALL ERRMSG( ferr_internal, status, 'xtra MR_NOT_IN_USE', *5000)
	ENDIF

* possibly insert the variable at the head of the deletion priority chain
	IF ( mr_protected(mr) .EQ. mr_not_protected ) THEN

* 12/16 - sanity check if it is already in the deletion chain before
*         attempting to insert it again. Doubly inserting can occur
*         only if this routine is called more often than it should be
*         signaling an internal error
	   IF (mr_del_flink(mr) .NE. unspecified_int4 ) THEN
	      CALL ERRMSG( ferr_internal, status, 'MR_NOT_IN_USE', *5000)
	   ELSE

	   last_head = mr_del_flink(0)
	   mr_del_blink(mr) = 0
	   mr_del_flink(mr) = last_head
	   mr_del_flink(0)  = mr
	   mr_del_blink(last_head) = mr

	   ENDIF
	ENDIF

 5000	RETURN
	END
