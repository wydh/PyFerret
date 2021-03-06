*
* status.F
*
* Jonathan Callahan
* Feb 19th 1998
*
* This function checks the input variable for bad data
* and returns 0 (no bad flags) or 1 (bad flags found)
*
* NB_ External functions need to have regions defined on
*     the arguments to have those regions used in the
*     external function calculation.  Regions defined
*     with SET REGION will not have the desired effect.
*
*     Use a command like:
*
*     let a = status(sst[x=180:160w,y=0:20n,l=1])
*


*
* In this subroutine we provide information about
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


      SUBROUTINE status_init(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id, arg



* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      CALL ef_set_desc(id,'test for bad flags in data' )

      CALL ef_set_num_args(id, 1)
      CALL ef_set_axis_inheritance(id, NORMAL, 
     .     NORMAL, NORMAL, IMPLIED_BY_ARGS)
      CALL ef_set_piecemeal_ok(id, NO, NO, NO, NO)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'A')
      CALL ef_set_arg_unit(id, arg, 'none')
      CALL ef_set_arg_desc(id, arg, 'data to be checked')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, YES)
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END


*
* In this subroutine we compute the result
*
      SUBROUTINE status_compute(id, arg_1, result)

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

	  INTEGER id

      REAL bad_flag(1:EF_MAX_ARGS), bad_flag_result
      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, 
     .           mem1loz:mem1hiz, mem1lot:mem1hit)
      REAL result(memreslox:memreshix, memresloy:memreshiy,
     .            memresloz:memreshiz, memreslot:memreshit)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable's axes. 

      INTEGER res_lo_ss(4), res_hi_ss(4), res_incr(4)
      INTEGER arg_lo_ss(4,1:EF_MAX_ARGS), arg_hi_ss(4,1:EF_MAX_ARGS),
     .     arg_incr(4,1:EF_MAX_ARGS)


* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER i,j,k,l
      INTEGER i1, j1, k1, l1

      CALL ef_get_res_subscripts(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

      print *, ' result lo limits', res_lo_ss
      print *, ' result hi limits', res_hi_ss

* We'll give the data the benefit of the doubt and assume that
* it's good unless we find out otherwise.

      DO 40 i=res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)
         DO 30 j=res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)
            DO 20 k=res_lo_ss(Z_AXIS), res_hi_ss(Z_AXIS)
               DO 10 l=res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)

                  result(i,j,k,l) = 0

 10            CONTINUE
 20         CONTINUE
 30      CONTINUE
 40   CONTINUE

*
* Note that we are looping on the argument subscripts rather than
* the result subscripts (the normal way).  That's because the result
* has axes which are normal and the loop count on those normal axes 
* will be one.
*
      i = res_lo_ss(X_AXIS)
      DO 400 i1=arg_lo_ss(X_AXIS,ARG1), arg_hi_ss(X_AXIS,ARG1)

         j = res_lo_ss(Y_AXIS)
         DO 300 j1=arg_lo_ss(Y_AXIS,ARG1), arg_hi_ss(Y_AXIS,ARG1)

            k = res_lo_ss(Z_AXIS)
            DO 200 k1=arg_lo_ss(Z_AXIS,ARG1), arg_hi_ss(Z_AXIS,ARG1)

               l = res_lo_ss(T_AXIS)
               DO 100 l1=arg_lo_ss(T_AXIS,ARG1), arg_hi_ss(T_AXIS,ARG1)

                  IF ( arg_1(i1,j1,k1,l1) .EQ. bad_flag(1) ) THEN

                     result(i,j,k,l) = 1

                  END IF

                  l = l + res_incr(T_AXIS)
                  
 100           CONTINUE

               k = k + res_incr(Z_AXIS)
 200        CONTINUE

            j = j + res_incr(Y_AXIS)
 300     CONTINUE

         i = i + res_incr(X_AXIS)
 400  CONTINUE
      
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END
