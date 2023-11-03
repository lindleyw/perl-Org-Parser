#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Org::Parser;
use Test::More 0.96;
require "testlib.pl";

test_parse(
    name => 'seniority(), prev_sibling(), next_sibling()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* h1
** h2a
** h2b
** h2c
_
    num => 4,
    test_after_parse => sub {
        my (%args) = @_;
        my $h = $args{elements};
        is($h->[0]->seniority, 0, "h1's seniority=0");
        is($h->[1]->seniority, 0, "h2a's seniority=0");
        is($h->[2]->seniority, 1, "h2b's seniority=1");
        is($h->[3]->seniority, 2, "h2c's seniority=2");

        ok(!defined($h->[0]->prev_sibling), "h1 doesnt have prev_sibling");
        ok(!defined($h->[1]->prev_sibling), "h2a doesnt have prev_sibling");
        is($h->[2]->prev_sibling->title->as_string, "h2a",
           "h2b's prev_sibling=h2a");
        is($h->[3]->prev_sibling->title->as_string, "h2b",
           "h2c's pre_sibling=h2b");

        ok(!defined($h->[0]->prev_sibling), "h1 doesnt have next_sibling");
        is($h->[1]->next_sibling->title->as_string, "h2b",
           "h2a's next_sibling=h2b");
        is($h->[2]->next_sibling->title->as_string, "h2c",
           "h2b's next_sibling=h2c");
        ok(!defined($h->[3]->next_sibling), "h2c doesnt have next_sibling");
    },
);

test_parse(
    name => 'walk()',
    doc  => <<'_',
#comment
* h <2011-03-22 >
text
_
    test_after_parse => sub {
        my (%args) = @_;
        my $doc = $args{result};

        my $n=0;
        $doc->walk(sub{$n++});
        # 1 = document itself
        # 3 = comment + headline + 'text'
        # 1 = title
        # 2 = title's children: text 'h ' + timestamp
        is($n, 7, "num of walked elements");
    },
);

test_parse(
    name => 'walk() still walks entire children even when '.
        'a child is removed in the middle',
    doc  => <<'_',
* a
* b
* c
* d
* e
_
    test_after_parse => sub {
        my (%args) = @_;
        my $doc = $args{result};

        my $n=0;
        $doc->walk(
            sub{
                my $el = shift;
                if ($el->isa("Org::Element::Headline")) {
                    $n++;
                    if ($n == 3) {
                        splice @{$doc->children}, 3, 1;
                    }
                }
            }
        );
        is($n, 5, "num of walked elements");
        is(scalar(@{ $doc->children }), 4, "current num of children");
    },
);
test_parse(
    name => 'find(), walk_parents(), headline(), headlines()',
    doc  => <<'_',
* a
** b
*** c
**** d
text
**** d2
_
    test_after_parse => sub {
        my (%args) = @_;
        my $doc = $args{result};
        my @res = $doc->find(
            sub {
                $_[0]->isa('Org::Element::Headline') &&
                    $_[0]->title->as_string =~ /^d/;
            });
        is(scalar(@res), 2, "find num results");
        ok($res[1]->isa("Org::Element::Headline") &&
               $res[1]->title->as_string eq 'd2', "find result #2");

        my $d = $res[0];
        my $res = "";
        $d->walk_parents(
            sub {
                my ($el, $parent) = @_;
                return if $parent->isa('Org::Document');
                $res .= $parent->title->as_string;
            });
        is($res, "cba", "walk_parents()");

        is($d->headline->title->as_string, "c", "headline() 1");
        is($d->children->[0]->headline->title->as_string, "d", "headline() 2");

        {
            my @res = $d->headlines;
            is(scalar(@res), 3, "headlines() count");
            is($res[0]->title->as_string, "c", "headlines() 1");
            is($res[1]->title->as_string, "b", "headlines() 2");
            is($res[2]->title->as_string, "a", "headlines() 3");
        }
    },
);

test_parse(
    name => 'remove()',
    doc  => <<'_',
* a
* b
** b2
*** b3
* c
_
    filter_elements => 'Org::Element::Headline',
    num => 5,
     test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};
        my ($a, $b, $b2, $b3, $c) = @$elems;

        $b->remove;
        my @res = $doc->find('Headline');
        is(scalar(@res), 2, "remove() removes children");
        is(scalar(@{$doc->children}), 2,
           "remove() removes from parent's children");
        is($a->next_sibling, $c, "a's next_sibling becomes c");
        is($c->prev_sibling, $a, "c's prev_sibling becomes a");
    },
);

done_testing();
