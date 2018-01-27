/* Python.h should always be first */
#include <Python.h>
#include <cairo/cairo.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include "grdel.h"
#include "cferbind.h"
#include "cairoCFerBind.h"

/*
 * Draw discrete points in this "Window".
 *
 * Returns one if successful.   If an error occurs, grdelerrmsg
 * is assigned an appropriate error message and zero is returned.
 */
grdelBool cairoCFerBind_drawPoints(CFerBind *self, double ptsx[], double ptsy[],
                                   int numpts, grdelType symbol, grdelType color,
                                   double symsize)
{
    CairoCFerBindData *instdata;
    CCFBSymbol *symbolobj;
    CCFBColor  *colorobj;
    int    k;
    double unitfactor;
    double scalefactor;

    /* Sanity check */
    if ( (self->enginename != CairoCFerBindName) &&
         (self->enginename != PyQtCairoCFerBindName) ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                            "self is not a valid CFerBind struct");
        return 0;
    }
    instdata = (CairoCFerBindData *) self->instancedata;
    if ( instdata->context == NULL ) {
        /* Create the Cairo Surface and Context if they do not exist */
        if ( ! cairoCFerBind_createSurface(self) ) {
            /* grdelerrmsg already assigned */
            return 0;
        }
    }
    symbolobj = (CCFBSymbol *) symbol;
    if ( symbolobj->id != CCFBSymbolId ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                            "symbol is not CCFBSymbol struct");
        return 0;
    }
    colorobj = (CCFBColor *) color;
    if ( colorobj->id != CCFBColorId ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPoints: unexpected error, "
                            "color is not CCFBColor struct");
        return 0;
    }

    /* Assign the (solid) color to use for the symbols */
    if ( instdata->noalpha )
        cairo_set_source_rgb(instdata->context, colorobj->redfrac,
                             colorobj->greenfrac, colorobj->bluefrac);
    else
        cairo_set_source_rgba(instdata->context, colorobj->redfrac,
                              colorobj->greenfrac, colorobj->bluefrac,
                              colorobj->opaquefrac);

    /* Conversion factor for those surfaces that expect points instead of pixels */
    if ( instdata->imageformat == CCFBIF_PNG ) {
        unitfactor = 1.0;
    }
    else {
        unitfactor = 72.0 / instdata->pixelsperinch;
    }

    /* Scaling factor to use for these symbols "drawn" as 100x100 pixel paths */
    scalefactor  = symsize * instdata->widthfactor;
    scalefactor *= unitfactor / 100.0;

    /* Draw the scaled symbol at each point */
    cairo_new_path(instdata->context);
    for (k = 0; k < numpts; k++) {
        cairo_new_sub_path(instdata->context);
        cairo_save(instdata->context);
        /* Move origin to the location for the point */
        cairo_translate(instdata->context, ptsx[k] * unitfactor, ptsy[k] * unitfactor);
        /* Scale so the symbol is drawn the correct size */
        cairo_scale(instdata->context, scalefactor, scalefactor);
        /* Draw the symbol */
        cairo_append_path(instdata->context, symbolobj->path);
        cairo_restore(instdata->context);
    }
    if ( symbolobj->filled ) {
        cairo_fill(instdata->context);
    }
    else {
        cairo_stroke(instdata->context);
    }

    instdata->somethingdrawn = 1;
    instdata->imagechanged = 1;
    return 1;
}

