#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use DateTime;
use Org::Parser;
use Test::More 0.96;
require "testlib.pl";

test_parse(
    name => 'active timestamp',
    filter_elements => sub {
        $_[0]->isa('Org::Element::Timestamp') },
    doc  => <<'_',
* TODO active timestamps
  SCHEDULED: <2011-03-16 Wed>
  TEST: <2011-03-16 >
  TEST: <2011-03-16 Wed 01:23>
  nontimestamps: <2011-03-23>

* inactive timestamps
  - [2011-03-23 Wed]
  - [2011-03-23 ]
  - [2011-03-23 Wed 01:23]
  - nontimestamps: [2011-03-23]
_
    num => 6,
    test_after_parse => sub {
        my %args = @_;
        my $doc = $args{result};
        my $elems = $args{elements};
        is(DateTime->compare(DateTime->new(year=>2011, month=>3, day=>16),
                             $elems->[0]->datetime), 0, "ts[0] datetime");
        ok( $elems->[0]->is_active, "ts[0] is_active");
        ok(!$elems->[3]->is_active, "ts[3] !is_active");
    },
);

done_testing();
