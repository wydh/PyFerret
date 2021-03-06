	SUBROUTINE TM_allo_tmp_line( line, status )

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

* Allocate a temporary line from the dynamic line area (above max_lines)

* Steve Hankin  NOAA/PMEL/TMAP

* V510 *sh* 3/00 - guts of routine in  TM_ALLO_DYN_LINE_SUB
* V581*acm*  6/05 For fix to bug 1271, add flag line_shift_origin
* v694 1/15 *acm* (see ticket 2227) handle the line_dim_only flag
* V720 4/17 *sh* added line_dsg_dset

* Include files
	include 'tmap_dims.parm'
	include 'implicit.parm'
	include 'tmap_errors.parm'
#include "tmap_dset.parm"
	include 'xtm_grid.cmn_text'

* Argument definitions
	INTEGER line, status

	CALL TM_ALLO_DYN_LINE_SUB( tmp_line_hook, line, status )
	IF ( status .NE. merr_ok) RETURN

* initialize the line to a null content
	line_name(line)	     = char_init16
        line_t0(line)        = char_init20
        line_shift_origin(line) = .FALSE.
        line_tunit(line)     = real4_init
        line_parent(line)    = 0
        line_regular(line)   = .TRUE.
        line_class(line)     =  pline_class_basic
        line_direction(line) = 'NA'
        line_modulo(line)    = .FALSE.
        line_units(line)     = char_init16
	line_unit_code(line) = int4_init
        line_start(line)     = real8_init
        line_delta(line)     = real8_init
        line_dim(line)       = int4_init

	line_subsc1(line)    = int4_init
	line_dim_only(line)  = .FALSE.

	line_dsg_dset(line)  = pline_not_dsg

	RETURN
	END
