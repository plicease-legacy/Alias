use lib ".";
require Alias;
use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'Alias',
	      VERSION => sprintf("%.2f",$Alias::VERSION),
	      dist => {COMPRESS=>'gzip -9f'},
	      'macro' => {CONFIGDEP => 'Alias.pm'}

	     );

