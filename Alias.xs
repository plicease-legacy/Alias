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
static void process_flag _((char *varname, SV **svp, char **strp, STRLEN *lenp));

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

static void
process_flag(varname, svp, strp, lenp)
    char *varname;
    SV **svp;
    char **strp;
    STRLEN *lenp;
{
    GV *vargv = gv_fetchpv(varname, FALSE, SVt_PV);
    SV *sv = Nullsv;
    char *str = Nullch;
    STRLEN len = 0;

    if (vargv && (sv = GvSV(vargv))) {
	if (SvROK(sv)) {
	    if (SvTYPE(SvRV(sv)) != SVt_PVCV)
		croak("$%s not a subroutine reference", varname);
	}
	else if (SvOK(sv))
	    str = SvPV(sv, len);
    }
    *svp = sv;
    *strp = str;
    *lenp = len;
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
		SV *val, *tmpsv;
		char *key;
		I32 klen;
		SV *keypfx, *attrpfx;
		char *keypfx_c, *attrpfx_c;
		STRLEN keypfx_l, attrpfx_l;

		process_flag("Alias::KeyFilter", &keypfx, &keypfx_c, &keypfx_l);
		process_flag("Alias::AttrPrefix", &attrpfx, &attrpfx_c, &attrpfx_l);

		LEAVE;                      /* operate at a higher level */
		
		(void)hv_iterinit(hv);
		while ((val = hv_iternextsv(hv, &key, &klen))) {
		    GV *gv;
		    int stype = SvTYPE(val);

		    /* check the key for validity by either looking at
		     * its prefix, or by calling &$Alias::KeyFilter */
		    if (keypfx) {
			if (keypfx_c) {
			    if (keypfx_l && klen > keypfx_l
				&& strncmp(key, keypfx_c, keypfx_l))
				continue;
			}
			else {
			    dSP;
			    SV *ret = Nullsv;
			    I32 i;
			    
			    ENTER;
			    SAVETMPS;
			    PUSHMARK(sp);
			    XPUSHs(sv_2mortal(newSVpv(key,klen)));
			    PUTBACK;
			    if (perl_call_sv(keypfx, G_SCALAR))
				ret = *stack_sp--;
			    SPAGAIN;
			    i = SvTRUE(ret);
			    FREETMPS;
			    LEAVE;
			    if (!i)
				continue;
			}
		    }

		    /* attributes may need to be prefixed/renamed */
		    if (attrpfx) {
			STRLEN len;
			if (attrpfx_c) {
			    if (attrpfx_l) {
				SV *keysv = sv_2mortal(newSVpv(attrpfx_c, attrpfx_l));
				sv_catpvn(keysv, key, klen);
				key = SvPV(keysv, len);
				klen = len;
			    }
			}
			else {
			    dSP;
			    SV *ret = Nullsv;
			    
			    ENTER;
			    PUSHMARK(sp);
			    XPUSHs(sv_2mortal(newSVpv(key,klen)));
			    PUTBACK;
			    if (perl_call_sv(attrpfx, G_SCALAR))
				ret = *stack_sp--;
			    SPAGAIN;
			    /* can't FREETMPS since we want ret until later */
			    LEAVE;
			    key = SvPV_force(ret, len);
			    klen = len;
			}
		    }

		    if (SvROK(val))  {
			if ((tmpsv = SvRV(val))) {
			    stype = SvTYPE(tmpsv);
			    if (stype == SVt_PVGV)
				val = tmpsv;
			}
		    }
		    else if (stype != SVt_PVGV)
			val = sv_2mortal(newRV(val));

		    /* add symbol, forgoing "used once" warnings */
		    gv = gv_fetchpv(key, GV_ADDMULTI, SVt_PVGV);
		    
		    switch (stype) {
		    case SVt_PVAV:
			save_ary(gv);
			break;
		    case SVt_PVHV:
			save_hash(gv);
			break;
		    case SVt_PVGV:
			save_gp(gv);	    /* hide previous entry in symtab */
			break;
		    case SVt_PVCV:
			SAVESPTR(GvCV(gv));
			GvCV(gv) = Null(CV*);
			break;
		    default:
			save_scalar(gv);
			break;
		    }
		    sv_setsv((SV*)gv, val); /* alias the SV */
		}
		ENTER;			    /* in lieu of the LEAVE far beyond */
	    }
	    SvREFCNT_dec(hashref);
	    XPUSHs(hashref);                /* simply return what we got */
	}
