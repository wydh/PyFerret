/* Python.h should always be first */
#include <Python.h>
#include <stdio.h>
#include <string.h>
#include "cferbind.h"
#include "cairoCFerBind.h"
#include "grdel.h"

/*
 * Draw discrete points in this "Window".
 *
 * Currently stubbed since it is currently not used by Ferret;
 * thus always fails.
 *
 * Returns one if successful.   If an error occurs, grdelerrmsg
 * is assigned an appropriate error message and zero is returned.
 */
grdelBool cairoCFerBind_drawPoints(CFerBind *self, double ptsx[], double ptsy[],
                                   int numpts, grdelType symbol, grdelType color,
                                   double symsize)
{
    CCFBColor *colorobj;

    /* Sanity check */
    if ( self->enginename != CairoCFerBindName ) {
        sprintf(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                             "self is not a %s CFerBind struct", CairoCFerBindName);
        return 0;
    }
    colorobj = (CCFBColor *) color;
    if ( colorobj->id != CCFBColorId ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                            "color is not CCFBColor struct");
        return 0;
    }

    /* TODO: implement */
    strcpy(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                        "stubbed function");
    return 0;
}
