#
# Documentation at the __END__
#

package Alias;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(alias);
@EXPORT_OK = qw(const);
$VERSION = 1.0;

sub alias {
    my($i) = scalar(@_) - 1 ;
    my($j) = $i-1;
    die "Need even number of args" if $j % 2;
    my($pkg) = caller;            # for namespace soundness
    while ($j >= 0) { 
        if ('GLOB' eq ref $_[$i]) { *{"$pkg\:\:$_[$j]"} = ${$_[$i]} }
        elsif (ref $_[$i])        { *{"$pkg\:\:$_[$j]"} = $_[$i] }
        else                      { *{"$pkg\:\:$_[$j]"} = \$_[$i] }
        $i--; $j--;
    }
}

alias const => \&alias;           # alias the alias :-)

1;
__END__

=head1 NAME

Alias - declare perl aliases and constants


=head1 SYNOPSIS

    use Alias qw(alias const);
    alias TEN => $ten, Ten => \$ten, Ten => \&ten,
          Ten => \@ten, Ten => \%ten, TeN => \*ten;
    {
       local @Ten;
       my $ten = [1..10];
       alias Ten => $ten;   # local @Ten
    }

    const pi => 3.14, ten => 10;


=head1 DESCRIPTION

Given a list of alias-symbol => value pairs, declares aliases
in the caller's namespace. If the value supplied is a reference, the
alias is created for the underlying value instead of the reference
itself (since no one will use this package to alias references--they
are automatically "aliased" on assignment).  This allows the user to
alias all of Perl's basic types.

If the value supplied is a compile-time constant, the aliases become
read-only. Any attempt to write to them will fail with a run time
error. A function-alias C<const> is aliased by this package (on demand)
for C<alias>, since this reads better for constant declarations.

Aliases can be dynamically scoped by pre-declaring the target symbol as
a C<local>.


=head1 EXAMPLES

    use Alias qw(alias const);
    $ten = 10;
    alias TEN => $ten, Ten => \$ten, Ten => \&ten,
    	  Ten => \@ten, Ten => \%ten;
    alias TeN => \*ten;  # same as *TeN = *ten
    const _TEN_ => 10;
     
    $ten = 20;   
    print "$TEN|$Ten|$ten\n";
    sub ten { print "10\n"; }
    @ten = (1..10);
    %ten = (a..j);
    &Ten;
    print @Ten, "|", %Ten, "\n";

    @DYNAMIC = qw(m n o);
    {
       my $tmp = [ qw(a b c d) ];
       local @DYNAMIC;
       alias DYNAMIC => $tmp, PERM => $tmp;
       $DYNAMIC[2] = 'zzz';
       print @$tmp, "|", @DYNAMIC, "|", @PERM, "\n";
       @DYNAMIC = qw(p q r);
       print @$tmp, "|", @DYNAMIC, "|", @PERM, "\n";
    }
    print @DYNAMIC, "|", @PERM, "\n";

    $_TEN_ = 20;


=head1 NOTES

It is worth repeating that the aliases will be created in the caller's
namespace.  If that namespace happens to be C<local>ized, the alias
created will be local to that block.  This enables the use of dynamically
scoped aliases.

Aliases cannot be lexical, since, by necessity, they live on the
symbol table. 

Lexicals can be aliased. Note that this gives us a means of reversing
the action of anonymous type generators C<\>, C<[]> and C<{}>.  Which
means you can anonymously construct data and give it a symboltable
presence when you choose.

Remember that aliases are very much like references, only you don't
have to de-reference them as often.  Which means you won't have to
pound on the dollars so much.

It is possible to alias packages, but that might be construed as
abuse.

Using this package will lead to a much reduced urge to use typeglobs.


=head1 AUTHOR

Gurusamy Sarathy                gsar@umich.edu

=cut



