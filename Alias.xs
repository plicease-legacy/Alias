#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define save_gp my_save_gp

static void my_save_gp _((GV *gv));

/* copied verbatim from scope.c because it is #ifdeffed out -- WHY??? */
static void
my_save_gp(gv)
GV *gv;
{
    register GP *gp;
    GP *ogp = GvGP(gv);

    SSCHECK(3);
    SSPUSHPTR(SvREFCNT_inc(gv));
    SSPUSHPTR(ogp);
    SSPUSHINT(SAVEt_GP);

    Newz(602,gp, 1, GP);
    GvGP(gv) = gp;
    GvREFCNT(gv) = 1;
    GvSV(gv) = NEWSV(72,0);
    GvLINE(gv) = curcop->cop_line;
    GvEGV(gv) = gv;
}


MODULE = Alias		PACKAGE = Alias		PREFIX = alias_

PROTOTYPES: ENABLE

void
alias_attr(hashref)
	SV *	hashref
	PROTOTYPE: $
     PPCODE:
	{
	    HV *hv;
	    
	    (void)SvREFCNT_inc(hashref);    /* in case LEAVE wants to clobber us */

	    if (SvROK(hashref) &&
		(hv = (HV *)SvRV(hashref)) && (SvTYPE(hv) == SVt_PVHV))
	    {
		SV *val;
		SV *tmpsv;
		char *key;
		I32 klen;
		
		LEAVE;                      /* operate at a higher level */
		
		(void)hv_iterinit(hv);
		while (val = hv_iternextsv(hv, &key, &klen)) {
		    GV *gv;
		    int stype = SvTYPE(val);
		    
		    if (SvROK(val))  {
			if ((tmpsv = SvRV(val))) {
			    stype = SvTYPE(tmpsv);
			    if (stype == SVt_PVGV)
				val = tmpsv;
			}
		    }
		    else if (stype != SVt_PVGV)
			val = sv_2mortal(newRV(val));

		    gv = gv_fetchpv(key, TRUE, SVt_PVGV);
		    switch (stype) {
		    case SVt_PVAV:
			save_ary(gv);
			break;
		    case SVt_PVHV:
			save_hash(gv);
			break;
		    case SVt_PVGV:
			save_gp(gv);        /* hide previous entry in symtab */
			break;
		    case SVt_PVCV:
			SAVESPTR(GvCV(gv));
			GvCV(gv) = Null(CV*);
			break;
		    default:
			save_scalar(gv);
			break;
		    }
		    sv_setsv(gv, val);      /* alias the SV */
		}
		ENTER;                      /* in lieu of the LEAVE far beyond */
	    }
	    SvREFCNT_dec(hashref);
	    XPUSHs(hashref);                /* simply return what we got */
	}
