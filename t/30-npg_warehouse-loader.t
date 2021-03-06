use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use npg_tracking::Schema;
use npg_qc::Schema;

use t::npg_warehouse::util;

my $num_tests = 10;

SKIP: {

eval {
  npg_tracking::Schema->connect();
  1;
} or do {
  skip "Failed to connect to NPG DB : $@", $num_tests;
};
eval {
  npg_qc::Schema->connect();
  1;
} or do {
  skip "Failed to connect to NPGQC DB : $@", $num_tests;
};

my $schema_package = q[npg_warehouse::Schema];
my $fixtures_path = q[t/data/fixtures/warehouse];
my $schema_wh = t::npg_warehouse::util->new()->create_test_db($schema_package, $fixtures_path);
$schema_wh or die 'Failed to created warehouse test database';
use_ok('npg_warehouse::loader');

{
  my $loader = npg_warehouse::loader->new( 
                         _schema_wh => $schema_wh,
                         lims_driver_type => 'xml',
                         verbose    => 0,
                         id_run     => [1, 1937, 4950, 5316, 5970, 6566, 6589, 6857, 7110, 8398, 8284],
                                         );

  isa_ok($loader, 'npg_warehouse::loader');
  is ($loader->verbose, 0, 'verbose option is off');
  lives_ok {$loader->load()}   'loading to the warehouse db is ok';

TODO: {
  local $TODO = "Loading to the warehouse has different data than expected";
  my $row = $schema_wh->resultset('NpgInformation')->search({id_run=>4950, position=>1,})->next;

  lives_and {is $row->lane_type, 'pool'} 'lane type lives and is pool';
  lives_and{ is $row->sample_id, undef} 'sample undefined for a pool lane';
};   

  lives_ok {$schema_wh->resultset('NpgInformation')->update({sample_id => 11,})} 'updated sample id - OK';

TODO: { 
  local $TODO = "Loading to the warehouse has different data than expected";

  lives_and{  is $schema_wh->resultset('NpgInformation')->search({id_run=>4950, position=>1,})->next->sample_id, 11} 'sample id call lives and is 11 now';
};

  $loader = npg_warehouse::loader->new( 
                      _schema_wh => $schema_wh,
                      lims_driver_type => 'xml',
                      verbose    => 0,
                      id_run     => [4950],
                                      );
  lives_ok {$loader->load()}   'load run again';

TODO: {
  local $TODO = "Loading to the warehouse has different data than expected";

  lives_and{ is $schema_wh->resultset('NpgInformation')->search({id_run=>4950, position=>1,})->next->sample_id, undef} 'sample id can be called and is undef now';
};

}

}

1;
