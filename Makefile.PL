use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Alias',
    'VERSION'	=> '2.1',
    'linkext'   => {LINKTYPE => 'dynamic'},
    'dist'      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
);
