#!/usr/bin/perl

use Alias qw(alias const attr);

$TNUM = 0;

sub T { print "ok ", ++$TNUM, "\n" };

print "1..14\n";

$TEN = "";
$ten = 10;
$TWENTY = 20;
alias TEN => $ten, TWENTY => \*ten;
print '#\\$TEN is ', \$TEN, "\n";
print '#\\$ten is ', \$ten, "\n";
&T if \$TEN eq \$ten;
&T if $TEN eq $TWENTY;

const _TEN_ => \10;

eval { $_TEN_ = 20 };
&T if $@;

$dyn = "abcd";
{
  local $dyn;
  alias dyn => "pqrs";
  &T if $dyn eq "pqrs";
}
&T if $dyn eq "abcd";

my($lex) = 'abcd';
$closure = sub { return "$lex"; };
alias NAMEDCLOSURE => \&$closure;
$lex = 'pqrs';
&T if NAMEDCLOSURE() eq "pqrs";

package Foo;

# "in life", my moma always said, "you gotta pass those tests 
# before you can be o' some use to yerself" :-)
*T = \&main::T;    

use Alias;

sub new { bless { foo => 1, 
		  bar => [2,3], 
		  buz => { a => 4}, 
		  fuz => *easy, 
                  privmeth => sub { "private" },
                  easymeth => sub { die "to recurse or to die, is the question" },
		}, 
		$_[0]; 
}

sub easy { "gulp" }
sub easymeth {
  my $s = attr shift;  # localizes $foo, @bar, and %buz with hash values
  &T if defined($s) and ref($s) eq 'Foo';
  &T if defined (*fuz) and ref(\*fuz) eq ref(\*easy);
  print '#easy() is ', easy(), "\n";
  print '#fuz() is ', fuz(), "\n";
  &T if easy() eq fuz();
  eval { $s->easymeth };       # should fail
  print "#\$\@ is: $@\n";
  &T if $@;
  join '|', $foo, @bar, %buz, $s->privmeth;
}
$foo = 6;
@bar = (7,8);
%buz = (b => 9);
&T if Foo->new->easymeth eq '1|2|3|a|4|private';
&T if join('|', $foo, @bar, %buz) eq '6|7|8|b|9';

eval { fuz() };   # the local subroutine shouldn't be here now
print "# after fuz(): $@";
&T if $@;

eval { Foo->new->privmeth };   # private method shouldn't exist either
print "# after Foo->new->privmeth: $@";
&T if $@;


__END__
