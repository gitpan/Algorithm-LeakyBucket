use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::LeakyBucket',
    VERSION_FROM      => 'lib/Algorithm/LeakyBucket.pm', # finds $VERSION
    PREREQ_PM         => { 'Cache::Memcached::Fast' => '0.19' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/LeakyBucket.pm', # retrieve abstract from module
       AUTHOR         => 'Marcus Slagle <marc.slagle@online-rewards.com>') : ()),
);
