#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static void my_save_gp(GV *gv);

/* copied verbatim from scope.c because it is ifdeffed out there */
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


MODULE = Alias		PACKAGE = Alias

void
attr(href)
	SV *	href
     PPCODE:
	{
	    HV *hv;
	    
	    if (SvROK(href) && (hv = (HV *)SvRV(href)) && (SvTYPE(hv) == SVt_PVHV)) {
		SV *val;
		SV *tmpsv;
		char *key;
		I32 klen;
		HE *entry;
		
		SvREFCNT_inc(href);         /* so leave below doesn't clobber us */
		
		(void)hv_iterinit(hv);
		LEAVE;                      /* operate at a higher level */
		while (entry = hv_iternext(hv)) {
		    GV *gv;
		    key = hv_iterkey(entry, &klen);
		    val = hv_iterval(hv, entry);
		    
		    if (SvROK(val))  {
			if ((tmpsv = (GV *)SvRV(val)) && (SvTYPE(tmpsv) == SVt_PVGV))
			    val = tmpsv;
		    }
		    else
			val = sv_2mortal(newRV(val));
		    /* XXX may need to prepend caller's package to *key here */
		    gv = gv_fetchpv(key, TRUE, SVt_PVGV);
		    my_save_gp(gv);
		    sv_setsv(gv, val);
		}

		SvREFCNT_dec(href);
		ENTER;                   /* in lieu pp_leavesub()'s LEAVE */
	    }
	}
