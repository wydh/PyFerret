*
*  eofsvd_tfunc.F
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
*
* Ansley Manke
* July 2012
*
* Compute EOF/s and time amplitude funcions from a 2-d field, or for each level 
* of a 3-D field. Calls Billy Kessler's svdeof code
*
* Return time amplitude functions.
*
*
* In this SUBROUTINE we provide information about
* the function.  The user configurable information 
* consists of the following:
*
* descr              Text description of the function
*
* num_args           Required number of arguments
*
* axis_inheritance   Type of axis for the result
*                       ( CUSTOM, IMPLIED_BY_ARGS, NORMAL, ABSTRACT )
*                       CUSTOM          - user defined axis
*                       IMPLIED_BY_ARGS - same axis as the incoming argument
*                       NORMAL          - the result is normal to this axis
*                       ABSTRACT        - an axis which only has index values
*
* piecemeal_ok       For memory optimization:
*                       axes where calculation may be performed piecemeal
*                       ( YES, NO )
* 
*
* For each argument we provide the following information:
*
* name               Text name for an argument
*
* unit               Text units for an argument
*
* desc               Text description of an argument
*
* axis_influence     Are this argument's axes the same as the result grid?
*                       ( YES, NO )
*
* axis_extend       How much does Ferret need to extend arg limits relative to result 
*


      SUBROUTINE eofsvd_tfunc_init(id)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'

      INTEGER id, arg

************************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V
      CALL ef_set_desc(id,
     .   'Return SVD EOF time functions from XYT field.')

      CALL ef_set_num_args(id, 1)

      CALL ef_set_axis_inheritance_6d(id,
     .                                ABSTRACT,        NORMAL,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS)
      CALL ef_set_piecemeal_ok_6d(id, NO, NO, NO, NO, NO, NO)

      CALL ef_set_num_work_arrays(id, 9)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'A')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg,
     .                     'Variable in x,y,t; may be fcn of z,e,f')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              NO, NO, YES, YES, YES, YES)

*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
************************************************************************

      RETURN 
      END

*
* In this subroutine we provide information about the lo and hi
* limits associated with each abstract or custom axis.   The user 
* configurable information consists of the following:
*
* loss               lo subscript for an axis
*
* hiss               hi subscript for an axis
*

      SUBROUTINE eofsvd_tfunc_result_limits(id)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      INTEGER id
      INTEGER arg_lo_ss(6,EF_MAX_ARGS),
     .        arg_hi_ss(6,EF_MAX_ARGS),
     .        arg_incr (6,EF_MAX_ARGS)

* **********************************************************************
*                                           USER CONFIGURABLE PORTION |
*                                                                     |
*                                                                     V

      INTEGER my_lo_l, my_hi_l

      INTEGER nx, ny

*     Use utility functions to get context information about the 
*     1st argument, to set the abstract axis lo and hi indices.

      CALL ef_get_arg_subscripts_6d(id, arg_lo_ss, arg_hi_ss, arg_incr)

      nx = arg_hi_ss(X_AXIS, ARG1) - arg_lo_ss(X_AXIS, ARG1) + 1
      ny = arg_hi_ss(Y_AXIS, ARG1) - arg_lo_ss(Y_AXIS, ARG1) + 1

      my_lo_l = 1
      my_hi_l = nx * ny

      CALL ef_set_axis_limits(id, X_AXIS, my_lo_l, my_hi_l)

*                                                                     ^
*                                                                     |
*                                           USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END

*
* In this subroutine we request an amount of storage to be supplied
* by Ferret and passed as an additional argument.
*
      SUBROUTINE eofsvd_tfunc_work_size(id)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      INTEGER id

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

*
* Set the work arrays, X/Y/Z/T/E/F dimensions
*
* ef_set_work_array_dims_6d(id, array #,
*                           xlo, ylo, zlo, tlo, elo, flo,
*                           xhi, yhi, zhi, thi, ehi, fhi)
*
      COMMON /eof_tfuncSTOR/ mx
      INTEGER mx1, my1, mt1, mx, mxmt, mxmx, mwrk, mwrk2

      INTEGER iwork
      INTEGER arg_lo_ss(6,EF_MAX_ARGS),
     .        arg_hi_ss(6,EF_MAX_ARGS),
     .        arg_incr (6,EF_MAX_ARGS)

      CALL ef_get_arg_subscripts_6d(id, arg_lo_ss, arg_hi_ss, arg_incr)

      mx1 = 1 + arg_hi_ss(X_AXIS,ARG1) - arg_lo_ss(X_AXIS,ARG1)
      my1 = 1 + arg_hi_ss(Y_AXIS,ARG1) - arg_lo_ss(Y_AXIS,ARG1)
      mt1 = 1 + arg_hi_ss(T_AXIS,ARG1) - arg_lo_ss(T_AXIS,ARG1)

      mx = mx1 * my1 + 10
      mxmt = mx * mt1 + 10
      mxmx = mx * mx + 10
      mwrk = mxmt/2
      mwrk2 = MIN(mx, mt1)

*  taf (pack data into this eof by t array, returned as taf)
      iwork = 1
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                             mxmt, 1, 1, 1, 1, 1)

*  ok
      iwork = 2
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1,   1, 1, 1, 1, 1,
     .                              mx1, my1, 1, 1, 1, 1)

* workspace
      iwork = 3
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mwrk, 1, 1, 1, 1, 1)

* W(NX) eigenvalues of decomposition
      iwork = 4
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mx, 1, 1, 1, 1, 1)

* V(NX,NX) EOFs in columns (V(space,neof))
      iwork = 5
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mxmx, 2, 1, 1, 1, 1)

* PCT(NX) % variance represented by each EOF
      iwork = 6
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mx, 1, 1, 1, 1, 1)

*                                                            
*  isave_jsave
*  Make this work array 7, so that pack_ef from eofsubs can be used
      iwork = 7
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mx, 2, 1, 1, 1, 1)

* work2
      iwork = 8
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mwrk2, 1, 1, 1, 1, 1)

* work3
      iwork = 9
      CALL ef_set_work_array_dims_6d(id, iwork,
     .                                1, 1, 1, 1, 1, 1,
     .                               mwrk2, 1, 1, 1, 1, 1)
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END

*
* In this SUBROUTINE we compute the result
*

      SUBROUTINE  eofsvd_tfunc_compute(id, arg_1, result, 
     .    taf, ok, workspace, w, v, pct, isave_jsave, work2, work3)

*  arg_1  variable, function of (x,y,t)
*  result neof*NT time amplitude functions

*  Work arrays (there are some internal hard-coded arrays, should be 
*  done by external-functions work arrays).
*  taf, ok, isave_jsave, w, v, pct

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      COMMON /eof_tfuncSTOR/ mx
      INTEGER mx

      INTEGER id

      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, mem1loz:mem1hiz, 
     .           mem1lot:mem1hit, mem1loe:mem1hie, mem1lof:mem1hif)

      REAL result(memreslox:memreshix, memresloy:memreshiy, 
     .            memresloz:memreshiz, memreslot:memreshit,
     .            memresloe:memreshie, memreslof:memreshif)

*  Dimension the work arrays.


      REAL taf(wrk1lox:wrk1hix, wrk1loy:wrk1hiy,
     .         wrk1loz:wrk1hiz, wrk1lot:wrk1hit,
     .         wrk1loe:wrk1hie, wrk1lof:wrk1hif)
      REAL ok(wrk2lox:wrk2hix, wrk2loy:wrk2hiy,
     .        wrk2loz:wrk2hiz, wrk2lot:wrk2hit,
     .        wrk2loe:wrk2hie, wrk2lof:wrk2hif)
      REAL workspace(wrk3lox:wrk3hix, wrk3loy:wrk3hiy,
     .        wrk3loz:wrk3hiz, wrk3lot:wrk3hit,
     .        wrk3loe:wrk3hie, wrk3lof:wrk3hif)
      REAL w(wrk4lox:wrk4hix, wrk4loy:wrk4hiy,
     .        wrk4loz:wrk4hiz, wrk4lot:wrk4hit,
     .        wrk4loe:wrk4hie, wrk4lof:wrk4hif)
      REAL v(wrk5lox:wrk5hix, wrk5loy:wrk5hiy,
     .        wrk5loz:wrk5hiz, wrk5lot:wrk5hit,
     .        wrk5loe:wrk5hie, wrk5lof:wrk5hif)
      REAL pct(wrk6lox:wrk6hix, wrk6loy:wrk6hiy,
     .        wrk6loz:wrk6hiz, wrk6lot:wrk6hit,
     .        wrk6loe:wrk6hie, wrk6lof:wrk6hif)
      REAL isave_jsave(wrk7lox:wrk7hix, wrk7loy:wrk7hiy,
     .        wrk7loz:wrk7hiz, wrk7lot:wrk7hit,
     .        wrk7loe:wrk7hie, wrk7lof:wrk7hif)
      REAL work2(wrk8lox:wrk8hix, wrk8loy:wrk8hiy,
     .        wrk8loz:wrk8hiz, wrk8lot:wrk8hit,
     .        wrk8loe:wrk8hie, wrk8lof:wrk8hif)
      REAL work3(wrk9lox:wrk9hix, wrk9loy:wrk9hiy,
     .        wrk9loz:wrk9hiz, wrk9lot:wrk9hit,
     .        wrk9loe:wrk9hie, wrk9lof:wrk9hif)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable''s axes. 

      INTEGER res_lo_ss(6),
     .        res_hi_ss(6),
     .        res_incr (6)
      INTEGER arg_lo_ss(6,EF_MAX_ARGS),
     .        arg_hi_ss(6,EF_MAX_ARGS),
     .        arg_incr (6,EF_MAX_ARGS)

      REAL bad_flag(EF_MAX_ARGS), bad_flag_result

************************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER neof, ier
      CHARACTER*255 err_msg, err_out

      INTEGER nx, ny, nt, k, m, n, k1, m1, n1,
     .        iw, jw, kw, lw, mw, nw
      REAL frac_timeser

      CALL ef_get_res_subscripts_6d(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts_6d(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

*  get array sizes

      nx = 1 + arg_hi_ss(X_AXIS,ARG1) - arg_lo_ss(X_AXIS,ARG1)
      ny = 1 + arg_hi_ss(Y_AXIS,ARG1) - arg_lo_ss(Y_AXIS,ARG1)
      nt = 1 + arg_hi_ss(T_AXIS,ARG1) - arg_lo_ss(T_AXIS,ARG1)

      frac_timeser = 1.

*  Compute EOF for each depth, ensemble, forecast

      n1 = arg_lo_ss(F_AXIS,ARG1)
      DO 300 n = res_lo_ss(F_AXIS), res_hi_ss(F_AXIS)

      m1 = arg_lo_ss(E_AXIS,ARG1)
      DO 200 m = res_lo_ss(E_AXIS), res_hi_ss(E_AXIS)

      k1 = arg_lo_ss(Z_AXIS,ARG1)
      DO 100 k = res_lo_ss(Z_AXIS), res_hi_ss(Z_AXIS)

*  Initialize work arrays.

         DO 701 nw = wrk1lof,wrk1hif
         DO 701 mw = wrk1loe,wrk1hie
         DO 701 lw = wrk1lot,wrk1hit
         DO 701 kw = wrk1loz,wrk1hiz 
         DO 701 jw = wrk1loy,wrk1hiy
         DO 701 iw = wrk1lox,wrk1hix
            taf(iw,jw,kw,lw,mw,nw) = 0.
  701    CONTINUE

         DO 702 nw = wrk2lof,wrk2hif
         DO 702 mw = wrk2loe,wrk2hie
         DO 702 lw = wrk2lot,wrk2hit
         DO 702 kw = wrk2loz,wrk2hiz 
         DO 702 jw = wrk2loy,wrk2hiy
         DO 702 iw = wrk2lox,wrk2hix
            ok(iw,jw,kw,lw,mw,nw) = 0.
  702    CONTINUE

         DO 703 nw = wrk3lof,wrk3hif
         DO 703 mw = wrk3loe,wrk3hie
         DO 703 lw = wrk3lot,wrk3hit
         DO 703 kw = wrk3loz,wrk3hiz 
         DO 703 jw = wrk3loy,wrk3hiy
         DO 703 iw = wrk3lox,wrk3hix
            workspace(iw,jw,kw,lw,mw,nw) = 0.
  703    CONTINUE

         DO 704 nw = wrk4lof,wrk4hif
         DO 704 mw = wrk4loe,wrk4hie
         DO 704 lw = wrk4lot,wrk4hit
         DO 704 kw = wrk4loz,wrk4hiz 
         DO 704 jw = wrk4loy,wrk4hiy
         DO 704 iw = wrk4lox,wrk4hix
            w(iw,jw,kw,lw,mw,nw) = 0.
  704    CONTINUE

         DO 705 nw = wrk5lof,wrk5hif
         DO 705 mw = wrk5loe,wrk5hie
         DO 705 lw = wrk5lot,wrk5hit
         DO 705 kw = wrk5loz,wrk5hiz 
         DO 705 jw = wrk5loy,wrk5hiy
         DO 705 iw = wrk5lox,wrk5hix
            v(iw,jw,kw,lw,mw,nw) = 0.
  705    CONTINUE

         DO 706 nw = wrk6lof,wrk6hif
         DO 706 mw = wrk6loe,wrk6hie
         DO 706 lw = wrk6lot,wrk6hit
         DO 706 kw = wrk6loz,wrk6hiz 
         DO 706 jw = wrk6loy,wrk6hiy
         DO 706 iw = wrk6lox,wrk6hix
            pct(iw,jw,kw,lw,mw,nw) = 0.
  706    CONTINUE

         DO 707 nw = wrk7lof,wrk7hif
         DO 707 mw = wrk7loe,wrk7hie
         DO 707 lw = wrk7lot,wrk7hit
         DO 707 kw = wrk7loz,wrk7hiz 
         DO 707 jw = wrk7loy,wrk7hiy
         DO 707 iw = wrk7lox,wrk7hix
            isave_jsave(iw,jw,kw,lw,mw,nw) = 0.
  707    CONTINUE

         DO 708 nw = wrk8lof,wrk8hif
         DO 708 mw = wrk8loe,wrk8hie
         DO 708 lw = wrk8lot,wrk8hit
         DO 708 kw = wrk8loz,wrk8hiz 
         DO 708 jw = wrk8loy,wrk8hiy
         DO 708 iw = wrk8lox,wrk8hix
            work2(iw,jw,kw,lw,mw,nw) = 0.
  708    CONTINUE

         DO 709 nw = wrk9lof,wrk9hif
         DO 709 mw = wrk9loe,wrk9hie
         DO 709 lw = wrk9lot,wrk9hit
         DO 709 kw = wrk9loz,wrk9hiz 
         DO 709 jw = wrk9loy,wrk9hiy
         DO 709 iw = wrk9lox,wrk9hix
            work3(iw,jw,kw,lw,mw,nw) = 0.
  709    CONTINUE

*  Find the number of eofs to solve for. Require that a location has
*  all time points present or it is skipped.
*  neof = number of (x,y) points with all good data.  
*  Set OK to mark where they are. (note this also allows for 
*  working around continental boundaries or other areas where 
*  entire time series are missing)

         CALL count_neof (arg_1, neof, ok, nx, ny, nt, k1, m1, n1,
     .                    arg_lo_ss, arg_hi_ss, arg_incr, mx,
     .                    bad_flag(ARG1), frac_timeser, err_msg, ier)
         IF (ier .NE. 0) then
            GOTO 5010
         ENDIF
	 IF (neof .EQ. 0) THEN
	    err_msg = 'There are no spatial locations having complete time series.'
	    GOTO 5010
	 ENDIF

*  Put the data into the array taf(neof,nt). Input to solver routine,
*  returned as taf.

         CALL pack_ef (arg_1, taf, isave_jsave, neof,  
     .                 ok, frac_timeser, nx, ny, nt, k1, m1, n1,
     .                 arg_lo_ss, arg_hi_ss, arg_incr)

*  Solve for the EOF's: eigenvectors, time functions, percent variance explained.

         CALL solve_eofsvd_tfunc (taf, neof, nt, k, m, n, result, 
     .            isave_jsave, w, v, pct, workspace, work2, work3, 
     .            res_lo_ss, res_hi_ss, res_incr, bad_flag(ARG1),
     .            bad_flag_result, frac_timeser, err_msg, ier)

         IF (ier .NE. 0) GOTO 5020

         k1 = k1 + arg_incr(Z_AXIS,ARG1)
  100 CONTINUE
         m1 = m1 + arg_incr(E_AXIS,ARG1)
  200 CONTINUE
         n1 = n1 + arg_incr(F_AXIS,ARG1)
  300 CONTINUE

      RETURN

 5010 CALL ef_bail_out (id, err_msg)
      RETURN

 5020 IF (ier .EQ. -1) THEN
         err_msg = 'SVDEOF. No convergence in 60 iterations.'
      ENDIF
      WRITE (err_out, 5500) k, m, n, err_msg 
 5500 FORMAT ('k,m,n=', 3I3, A250)
      CALL ef_bail_out (id, err_out)
      RETURN

      END

***********************************************************************

      SUBROUTINE solve_eofsvd_tfunc (taf, neof, nt, k, m, n, result, 
     .            isave_jsave, w, v, pct, workspace, work2, work3,
     .            res_lo_ss, res_hi_ss, res_incr, bad_flag_dat, 
     .            bad_flag_result,frac_timeser, err_msg, ier)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      INTEGER neof, nt, k, m, n
      REAL w(*)
      REAL v(neof, neof)
      REAL taf(neof, nt)
      REAL pct(*)
      REAL workspace(*), work2(*), work3(*)
      REAL result(memreslox:memreshix, memresloy:memreshiy, 
     .            memresloz:memreshiz, memreslot:memreshit,
     .            memresloe:memreshie, memreslof:memreshif)
      REAL isave_jsave(wrk3lox:wrk3hix, wrk3loy:wrk3hiy,
     .        wrk3loz:wrk3hiz, wrk3lot:wrk3hit,
     .        wrk3loe:wrk3hie, wrk3lof:wrk3hif)
      INTEGER res_lo_ss(6), res_hi_ss(6), res_incr(6)
      REAL bad_flag_dat, bad_flag_result, frac_timeser
      CHARACTER*(*) err_msg
      INTEGER cnt, ier

* local variables
      INTEGER i, j, l, mm, nn, is, js

      CALL DO_SVD_EOF (taf, neof, nt, w, v, pct, workspace, 
     .                 work2, work3, ier)
      IF (ier .NE. 0) RETURN

*  Result is the time functions. 

      j = res_lo_ss(Y_AXIS)
      DO 120 i = 1, neof
         cnt = 1
         DO 110 l = res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)
            result(i,j,k,l,m,n) = taf(i,cnt)
            cnt = cnt + 1
  110    CONTINUE
  120 CONTINUE

      DO 220 i = neof+1, res_hi_ss(X_AXIS)
         DO 210 l = res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)
            result(i,j,k,l,m,n) = bad_flag_result
  210    CONTINUE
  220 CONTINUE

      RETURN
      END
