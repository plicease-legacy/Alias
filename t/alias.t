#!/usr/bin/perl

use Alias qw(alias const attr);

print "1..7\n";

$TEN = "";
$ten = 10;
alias TEN => $ten;
print "ok 1\n" if \$TEN eq \$ten;

const _TEN_ => \10;

eval { $_TEN_ = 20 };
print "ok 2\n" if $@;

$dyn = "abcd";
{
  local $dyn;
  alias dyn => "pqrs";
  print "ok 3\n" if $dyn eq "pqrs";
}
print "ok 4\n" if $dyn eq "abcd";

my($lex) = 'abcd';
$closure = sub { return "$lex"; };
alias NAMEDCLOSURE => \&$closure;
$lex = 'pqrs';
print "ok 5\n" if NAMEDCLOSURE() eq "pqrs";

package Foo;
use Alias;
sub new { bless { foo => 1, bar => [2,3], buz => { a => 4} }, $_[0]; }
sub easymeth {
  attr shift;     # localizes $foo, @bar, and %buz with hash values
  join '|', $foo, @bar, %buz;
}
$foo = 6;
@bar = (7,8);
%buz = (b => 9);
print "ok 6\n" if Foo->new->easymeth eq '1|2|3|a|4';
print "ok 7\n" if join('|', $foo, @bar, %buz) eq '6|7|8|b|9';
