	SUBROUTINE SPECIAL_SYMBOL( isym, name, value, slen )

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
*
* this routine is 2-in-1 to handle "special" (internally defined) symbols
* it acts like an encapsulated special symbol "object" (FORTRAN ...)
* if isym=0 on input then this is a request to translate the passed "name"
*	if the given name is the name of a special symbol return its definition
*	in value and its length in slen. Else return slen=0
* if slen is a positive integer then return the name of that symbol
*	or a blank name if the integer is larger than the number of symbols 

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* V522 7/00 *sh* - extracted from symbol_command.F
* V530  8/00 *sh* - bug (feature) fix so that SHOW SYM doesn't eveluate
*			PPL$XPIXEL
*      12/00 *sh* - added symbols SESSION_DATE and SESSION_TIME
*      10/01 *kob*- add symbol FERRET_PLATFORM to display the platform
*                   the executable was built on. 
*       8/05 *acm*- Allow more digits in xrevision number
* V62   4/09 *acm*- Add new symbol DELTA_CPU. When it is evaluated,
*                   calls the intrinsic fcn Dtime and sets the value to that new
*                   delta-time since the last call.  Initialized in initizlize.F
* V62   4/09 *acm*- Add new symbol CLOCK_SECS. When it is evaluated, calls the
*                   intrinsic SYSTEM_CLOCK and sets the value to the delta-time 
*                   in seconds since Ferret was initialized.
* V62   4/09 *acm*- Add new symbols CURRENT_DATE, CURRENT_TIME. These get formatted
*                   date and time, unlike SESSION_DATE, SESSION_TIME which remain
*                   fixed at the start time of the Ferret session.
* V62   5/09 *acm*- make FERRET_MEMORY a special symbol.
* V65   1/10 *acm*- New special symbol N_OPEN_DSETS, counts the number of open datasets
* V65   2/10 *acm*- Call CPU_TIME rather than DTIME for clock symbols. Works
*                   with gfortran as well as g77.
* V68  *acm* 1/12  ifdef double_p for double-precision ferret.
* V68   1/12 *acm*- Symbol FERRET_PRECISION is single or double.
* V68   3/12 *acm*- Symbol SESSION_PID for the process ID
* V68   2/13 *kms*- Symbol PROGRAM_NAME = Ferret or PyFerret
* V702  3/17 *sh* - Dynamic memory calculation change for FERRET_MEMORY symbol
*                 - added PEAK_MEMORY and SPAWN_STATUS
* v720 7/17 *acm* ticket 2552 Make SPAWN_STATUS return the return status, so 0=succcess
*                 SPAWN_OK -> SPAWN_OK, so 1=succcess, 0=failure
*                 SPAWN_STATUS returns the status value
* V751 6/19 *acm* Ticket 1903, reporting memory in bytes, so new symbol FERRET_BYTES_MEM

        IMPLICIT NONE
* calling argument declarations:
	INTEGER	  isym, slen
	CHARACTER name*(*), value*(*)

* internal parameter declaration
	INTEGER nspecial
	PARAMETER (nspecial = 21)

* internal variable declarations:
	LOGICAL	IS_SECURE
	INTEGER STR_UPCASE, TM_LENSTR, i, i1, ierr, wsid, 
     .          nxpix, nypix, llen, icount, irate, imax, iset
c        REAL DTIME 
        REAL TArray(2), dtime_res, clock_secs, count, cputime_now, rstatus
	CHARACTER special(nspecial)*16, upname*16
	CHARACTER LEFINT*16, TM_FMT*48, TM_FMT_TRIM*48, NF_INQ_LIBVERS*80,
     .		   NF_INQ_LIBVERS_*80,LEFINT8*16, byte_unit*2
        CHARACTER*10 current_date, current_time, zone
	INTEGER itimes(8)

* names of special symbols (must be upper case)
	DATA special(1)/ 'PPL$XPIXEL' /,
     .	     special(2)/ 'PPL$YPIXEL' /,
     .	     special(3)/ 'BYTEORDER' /,
     .	     special(4)/ 'FERRET_VERSION' /,
     .	     special(5)/ 'FERRET_PLATFORM' /,
     .	     special(6)/ 'FERRET_PRECISION' /,
     .	     special(7)/ 'NETCDF_VERSION' /,
     .	     special(8)/ 'FERRET_MEMORY' /,
     .	     special(9)/ 'FERRET_BYTES_MEM' /
     .	     special(10)/ 'SESSION_DATE' /,
     .	     special(11)/ 'SESSION_TIME' /,
     .	     special(12)/ 'SESSION_PID' /,
     .	     special(13)/ 'DELTA_CPU' /,
     .	     special(14)/ 'CLOCK_SECS' /,
     .	     special(15)/ 'CURRENT_DATE' /,
     .	     special(16)/ 'CURRENT_TIME' /,
     .	     special(17)/ 'N_OPEN_DSETS' /,
     .	     special(18)/ 'PROGRAM_NAME' /,
     .	     special(19)/ 'PEAK_MEMORY' /,
     .	     special(20)/ 'SPAWN_OK' /,
     .	     special(21)/ 'SPAWN_STATUS' /

	include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'xplot_state.cmn'	! for PPL$XPIXEL
	include 'xrevision.cmn'
	include 'xtoday.cmn'
	include 'xplatform_type.cmn'
	include 'xvariables.cmn'
#	include "tmap_dset.parm"
	include 'xdset_info.cmn_text'
	include 'xprog_state.cmn'	! for spawn_status

* #ifdef for endianness info.
#ifdef sun
	include 'xmachine_byte.cmn'
#else
	include 'xmachine_int1.cmn'
#endif

* is this a query by integer or by name?
	IF (isym .GE. 1) THEN 
* ***** QUERY BY INTEGER ******
	   IF (isym.GT.nspecial) THEN
	      name = ' '
	      RETURN
	   ENDIF
	   name = special(isym)
	   RETURN
	ENDIF

* ***** QUERY BY NAME *****
* identify the given name
	ierr = STR_UPCASE( upname, name )
	DO 100 i = 1, nspecial
	   IF (upname .EQ. special(i)) GOTO 200
 100	CONTINUE

* not a recognized special symbol
	slen = 0
	RETURN

 200	GOTO (1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 
     .        1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600,
     .        2700, 2800, 2900, 3000, 3100 ) i

* PPL$XPIXEL
* get the horizontal pixels size of the window as specified by the user
 1100   DO 1110 wsid = 1, max_windows
           IF ( wn_active(wsid) ) THEN
               value = LEFINT(NINT(wn_xpixels(wsid)),slen)
               RETURN
           ENDIF
 1110   CONTINUE
* ... no currently active window
        value = '0'
        slen = 1
        RETURN

* PPL$YPIXEL
* get the vertical pixels size of the window as specified by the user
 1200   DO 1210 wsid = 1, max_windows
           IF ( wn_active(wsid) ) THEN
               value = LEFINT(NINT(wn_ypixels(wsid)),slen)
               RETURN
           ENDIF
 1210   CONTINUE
* ... no currently active window
        value = '0'
        slen = 1
        RETURN

* BYTEORDER - get byteorder of this architecture
 1300	IF (active_cpu .EQ. cptype_sun) THEN
	   value = 'BIG'
	   slen = 3
	ELSE
	   value = 'LITTLE'
	   slen = 6
	ENDIF
	RETURN

* FERRET_VERSION
 1400	value = ' '
	value = TM_FMT(revision_level, 5, 12, llen)
	slen = llen
	RETURN

* PLATFORM_TYPE  *kob* 10/01
 1500	value = platform_type
	slen = TM_LENSTR(platform_type)
	RETURN

* FERRET_PRECISION
 1600	CONTINUE
#ifdef double_p
        value = 'double'
#else
        value = 'single'
#endif
	slen = TM_LENSTR(value)
	RETURN

* NETCDF_VERSION
 1700	CONTINUE
	value = NF_INQ_LIBVERS()
	slen = TM_LENSTR(value)
	RETURN

* FERRET_MEMORY
 1800	value = TM_FMT_TRIM(max_mem_allowed/1.D6,-2,12,llen)
	slen = llen
	RETURN

* FERRET_BYTES_MEM
 1900  CALL MEM_TO_BYTES (max_mem_allowed, value, llen, byte_unit)
       value = value(:llen)//byte_unit
       slen = llen + 2
       RETURN

* SESSION_DATE
 2000	value = today_date
	slen = 9
	RETURN

* SESSION_TIME
 2100	value = today_time
	slen = 5
	RETURN

* SESSION_PID
 2200	CONTINUE
	i1 = GETPID()
	count = i1
	value =  TM_FMT(count, 0, 10, slen)
	RETURN


* DELTA_CPU
 2300	CONTINUE
c        CALL DTIME(TArray)
	CALL CPU_TIME(cputime_now)
        dtime_res = cputime_now - cpu_last
	cpu_last = cputime_now
	value = ' '
	value = TM_FMT(dtime_res, 6, 8, slen)
	RETURN

* CLOCK_SECS
 2400	CALL SYSTEM_CLOCK(icount, irate, imax)
        clock_secs = FLOAT(icount-clock_start_count)/FLOAT(irate)
	IF (clock_secs .LT. 0) THEN
           CALL WARN('Evaluating CLOCK_SECS, call to '//
     .     'SYSTEM_CLOCK. Count has exceeded its max and reset.')
           CALL WARN( 'This value of CLOCK_SECS is invalid. '//
     .     'Resetting to new initial value.')
           clock_secs = 0.
	   clock_start_count = FLOAT(icount)/FLOAT(irate)
	ENDIF
	value = ' '
	value = TM_FMT_TRIM(clock_secs, -1, 8, slen)
	RETURN

* CURRENT_DATE
 2500	CONTINUE

#ifdef AIX_XLF
	CALL AIX_DATE( current_date )
#elif F90_DATE_TIME
	CALL FDATE(current_date)
#else
	CALL GET_DATE_AND_TIME (current_date, current_time)
#endif
        value = current_date
	slen = 9
	RETURN

* CURRENT_TIME
 2600	CONTINUE

#ifdef AIX_XLF
	CALL AIX_TIME( current_time )
#elif F90_DATE_TIME
	CALL FTIME(current_time)
#else
	CALL GET_DATE_AND_TIME (current_date, current_time)  ! doesnt get seconds

	CALL Date_and_Time(current_date, current_time, Zone, itimes)
        WRITE (current_time,1000) itimes(5), itimes(6), itimes(7)
 1000   FORMAT (2(I2.2,":"), I2.2)

#endif
	value = current_time
	slen = 8
	RETURN

* N_OPEN_DSETS
 2700	CONTINUE
 
	count = 0.
	DO iset = 1, maxdsets
	   IF ( ds_name(iset) .NE. char_init2048) count = count + 1.
	ENDDO

	value =  TM_FMT(count, 0, 10, slen)
	RETURN

* PROGRAM_NAME
 2800   CONTINUE

        value = 'PyFerret'
        slen = 8
        RETURN

* PEAK_MEMORY
 2900	value = LEFINT8(peak_mem,slen)
        RETURN

* SPAWN_OK
 3000   IF (IS_SECURE()) THEN
           rstatus = 0.
        ELSEIF (spawn_status .EQ. 0.) THEN
           rstatus = 1.
	ELSE
	   rstatus = 0.
	ENDIF
	value = TM_FMT(rstatus, 0, 10, slen)
        RETURN

* SPAWN_STATUS
 3100   IF (IS_SECURE()) THEN
	   value = 'secure: spawn not allowed'
	   slen = 25
        ELSE
           rstatus = spawn_status
           value = TM_FMT(rstatus, 0, 10, slen)
	ENDIf
        RETURN

	END

