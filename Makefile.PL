use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Alias',
    'VERSION'	=> '2.0',
    'linkext'   => {LINKTYPE => 'dynamic'},
    'dist'      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
);
