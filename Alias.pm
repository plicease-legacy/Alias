#
# Documentation at the __END__
#

package Alias;

require 5.001;
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(alias attr);
@EXPORT_OK = qw(const);

$VERSION = $VERSION = 2.0;

use Carp;

bootstrap Alias;

sub alias {
  croak "Need even number of args" if @_ % 2;
  my($pkg) = caller;              # for namespace soundness
  while (@_) {
    # you'd think *foo = \*bar would work. no.
    *{"$pkg\:\:$_[0]"} = (defined($_[1]) and ref($_[1])) ?
                            (ref($_[1]) eq 'GLOB') ? ${$_[1]} : $_[1] : \$_[1];
    shift; shift;
  }
}

# alias the elements of hash
# same as alias %{$_[0]}, but also localizes the aliases
sub attr;

alias const => \&alias;           # alias the alias :-)


1;
__END__

=head1 NAME

alias - declare symbolic aliases for perl data

attr  - auto-declare hash attributes for convenient access

const - define compile-time constants


=head1 SYNOPSIS

    use Alias qw(alias const attr);
    alias TEN => $ten, Ten => \$ten, Ten => \&ten,
          Ten => \@ten, Ten => \%ten, TeN => \*ten;
    {
       local @Ten;
       my $ten = [1..10];
       alias Ten => $ten;   # local @Ten
    }

    const pi => 3.14, ten => 10;

    package Foo;
    use Alias;
    sub new { bless {foo => 1, bar => [2, 3]}, $_[0] }
    sub method {
       attr shift;
       # $foo, @bar are now local aliases for $_[0]{foo}, @{$_[0]{bar}} etc.
    }

=head1 DESCRIPTION

Provides general mechanisms for aliasing perl data for convenient access.

=head2 Functions

=over 8

=item alias

Given a list of alias-symbol => value pairs, declares aliases
in the caller's namespace. If the value supplied is a reference, the
alias is created for the underlying value instead of the reference
itself (since no one will use this package to alias references--they
are automatically "aliased" on assignment).  This allows the user to
alias all of Perl's basic types.

If the value supplied is a compile-time constant, the aliases become
read-only. Any attempt to write to them will fail with a run time
error. 

Aliases can be dynamically scoped by pre-declaring the target symbol as
a C<local>.  Using C<attr> for is this purpose is more convenient, and
recommended.

=item attr

Given a hash reference, aliases the values of the hash to the names that
correspond to the keys.  The aliases are local to the enclosing block. If
any of the values are references, they are available as their dereferenced
types.  Thus the action is the same as saying:

    alias %{$_[0]}

but, in addition, also localizes the aliases.

This can be used for convenient access to hash values and hash-based object
attributes.  Note that this also makes available the semantics of C<local>
subroutines. Note also that such subroutines cannot be invoked via method
call syntax.  This is considered a feature.

=item const

This is simply a function alias for C<alias>, described above.  Provided on
demand at C<use> time, since it reads better for constant declarations.

=back

=head2 Exports

=over 8

=item alias

=item attr

=back

=head1 EXAMPLES

    use Alias qw(alias const attr);
    $ten = 10;
    alias TEN => $ten, Ten => \$ten, Ten => \&ten,
    	  Ten => \@ten, Ten => \%ten;
    alias TeN => \*ten;  # same as *TeN = *ten

    # aliasing basic types
    $ten = 20;   
    print "$TEN|$Ten|$ten\n";
    sub ten { print "10\n"; }
    @ten = (1..10);
    %ten = (a..j);
    &Ten;
    print @Ten, "|", %Ten, "\n";

    # dynamically scoped aliases
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

    # named closures
    my($lex) = 'abcd';
    $closure = sub { print $lex, "\n" };
    alias NAMEDCLOSURE => \&$closure;
    NAMEDCLOSURE();
    $lex = 'pqrs';
    NAMEDCLOSURE();

    # hash/object attributes
    package Foo;
    use Alias;
    sub new { bless { foo => 1, bar => [2,3], buz => { a => 4},
                      privsub => sub { "pseudo-private" } }, $_[0]; }
    sub easymeth {
      attr shift;     # localizes $foo, @bar, %buz etc with hash values
      print join '|', $foo, @bar, %buz, &privsub, "\n";
    }
    $foo = 6;
    @bar = (7,8);
    %buz = (b => 9);
    Foo->new->easymeth;
    print join '|', $foo, @bar, %buz, "\n";

    # should lead to run-time error
    const _TEN_ => 10;
    $_TEN_ = 20;


=head1 NOTES

It is worth repeating that the aliases created by C<alias> and C<const> will
be created in the caller's namespace.  If that namespace happens to be
C<local>ized, the aliases created will be local to that block.  C<attr>
localizes the aliases for you.

Aliases cannot be lexical, since, by necessity, they live on the
symbol table. 

Lexicals can be aliased. Note that this provides a means of reversing the
action of anonymous type generators C<\>, C<[]> and C<{}>.  This allows you
to anonymously construct data or code and give it a symbol-table presence
when you choose.

Any occurrence of C<::> or C<'> in names will be treated as package
qualifiers, and the value will be aliased in that namespace.

Remember that aliases are very much like references, only you don't
have to de-reference them as often.  Which means you won't have to
pound on the dollars so much.

You can make named closures with this scheme.

It is possible to alias packages, but that might be construed as
abuse.

Using this package will dramatically reduce noise characters in 
object-oriented perl code.

=head1 BUGS

Tied variables cannot be aliased properly, yet.

The special-cased GLOB situation owes itself to C<*foo = \*bar> being
broken in Perl.  One of these days..

=head1 VERSION

Version 2.0       1 Jan 1996

=head1 HISTORY

2.0    added implicit localization for C<attr> via XS code

1.3    Added C<attr> (unreleased)

1.2    Bugfix in the while loop, and other cleanup. Thanks to Ian Phillips
<ian@pipex.net>.

1.1    Added named closures to pod

1.0    Released to perl5-porters@nicoh.com


=head1 AUTHOR

Gurusamy Sarathy                gsar@umich.edu

Copyright (c) 1995 Gurusamy Sarathy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut


