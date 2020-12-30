#!perl

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";
use Test::More 0.98;

#use Org::Dump;
use Org::Parser;
require "testlib.pl";

test_parse(
    name => 'non-headline (missing space)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*h
_
    num => 0,
);

test_parse(
    name => 'non-headline (not on first column)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
 * h
_
    num => 0,
);

test_parse(
    name => 'non-headline (no title)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*
_
    num => 0,
);

test_parse(
    name => 'headline basic tests',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*   h1 1
** h2 1  :tag1:tag2:
*** h3 1  :invalid-tag:
text
*** TODO [#A] h3 2
    text
** DONE h2 2
* h1 2[#B][5/10]
* h1 3 [50%]
_
    num => 7,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        is($elems->[0]->title->as_string, "  h1 1", "0: title not trimmed");
        is($elems->[0]->level, 1, "0: level");

        is($elems->[1]->title->as_string, "h2 1", "1: title");
        is($elems->[1]->level, 2, "1: level");
        is_deeply($elems->[1]->tags, ['tag1', 'tag2'], "1: tags");

        is($elems->[2]->title->as_string, "h3 1  :invalid-tag:", "2: title");
        is($elems->[2]->level, 3, "2: level");

        is( $elems->[3]->title->as_string, "h3 2", "3: title");
        is( $elems->[3]->level, 3, "3: level");
        is( $elems->[3]->is_todo, 1, "3: is_todo");
        ok(!$elems->[3]->is_done, "3: is_done");
        is( $elems->[3]->todo_state, "TODO", "3: todo_state");
        is( $elems->[3]->priority, "A", "3: priority");

        is($elems->[4]->title->as_string, "h2 2", "4: title");
        is($elems->[4]->level, 2, "4: level");
        is($elems->[4]->is_todo, 1, "4: is_todo");
        is($elems->[4]->is_done, 1, "4: is_done");
        is($elems->[4]->todo_state, "DONE", "4: todo_state");
        # XXX default priority

        is($elems->[5]->title->as_string, "h1 2", "5: title");
        is($elems->[5]->level, 1, "5: level");
        is($elems->[5]->priority, "B", "5: priority");
        is($elems->[5]->statistics_cookie, "5/10", "5: statistics cookie (a/b style)");

        is($elems->[6]->title->as_string, "h1 3 ", "6: title");
        is($elems->[6]->level, 1, "6: level");
        is($elems->[6]->statistics_cookie, "50%", "6: statistics cookie (percent style)");
    },
);

test_parse(
    name => 'headline levels',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* h1
** h2
*** h3
**** h4
***** h5
* h1b
*** h3b
_
    num => 7,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        is($elems->[1]->parent->title->as_string, "h1", "parent of h2=h1");
        is($elems->[2]->parent->title->as_string, "h2", "parent of h3=h2");
        is($elems->[3]->parent->title->as_string, "h3", "parent of h4=h3");
        is($elems->[4]->parent->title->as_string, "h4", "parent of h5=h4");
        is($elems->[6]->parent->title->as_string, "h1b", "parent of h3b=h1b");
    },
);

test_parse(
    name => 'todo keyword is case sensitive',
    filter_elements => sub { $_[0]->isa('Org::Element::Headline') &&
                                 $_[0]->is_todo },
    doc  => <<'_',
* TODO 1
* Todo 2
* todo 3
* toDO 4
_
    num => 1,
);

test_parse(
    name => 'todo keyword can be separated by other \W aside from \s',
    filter_elements => sub { $_[0]->isa('Org::Element::Headline') &&
                                 $_[0]->is_todo },
    doc  => <<"_",
* TODO   1
* TODO\t2
* TODO+3a
* TODO+  3b
* TODO/4a
* TODO//4b

* TODO5a
* TODO_5b
_
    num => 6,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        is($elems->[0]->title->as_string, "1", "title 1");
        is($elems->[1]->title->as_string, "2", "title 2");
        is($elems->[2]->title->as_string, "+3a", "title 3");
        is($elems->[3]->title->as_string, "+  3b", "title 4");
        is($elems->[4]->title->as_string, "/4a", "title 5");
        is($elems->[5]->title->as_string, "//4b", "title 6");
    },
);

test_parse(
    name => 'inline elements in headline title',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* this headline contains timestamp <2011-03-17 > as well as text
_
    num => 1,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my $hl    = $elems->[0];
        my $title = $hl->title;
        isa_ok($title->children->[0], "Org::Element::Text");
        isa_ok($title->children->[1], "Org::Element::Timestamp");
        isa_ok($title->children->[2], "Org::Element::Text");
    },
);

test_parse(
    name => 'get_tags()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
#+FILETAGS: :t1:t2:
* a      :t3:
** b     :t4:
* c
_
    num => 3,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my $tags;
        $tags = [$elems->[0]->get_tags];
        is_deeply($tags, [qw/t3 t1 t2/], "get_tags 0") or diag explain $tags;
        $tags = [$elems->[1]->get_tags];
        is_deeply($tags, [qw/t4 t3 t1 t2/], "get_tags 1") or diag explain $tags;
        $tags = [$elems->[2]->get_tags];
        is_deeply($tags, [qw/t1 t2/], "get_tags 2") or diag explain $tags;
    },
);

test_parse(
    name => 'get_tags() (non-latin letters/numbers)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* a      :ü一:
* b      :ü二:
* c      :ü一:ü二:
_
    num => 3,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my $tags;
        $tags = [$elems->[0]->get_tags];
        is_deeply($tags, [qw/ü一/], "get_tags 0") or diag explain $tags;
        $tags = [$elems->[1]->get_tags];
        is_deeply($tags, [qw/ü二/], "get_tags 1") or diag explain $tags;
        $tags = [$elems->[2]->get_tags];
        is_deeply($tags, [qw/ü一 ü二/], "get_tags 3") or diag explain $tags;
    },
);

test_parse(
    name => 'get_active_timestamp()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* TODO <2011-06-06 > t0
* TODO t1 <2011-06-06 >
* TODO t2
  DEADLINE: <2011-06-06 >
  DEADLINE: <2011-06-07 >
* TODO [2011-06-06 ] t3
* TODO t4
_
    num => 5,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        ok( $elems->[0]->get_active_timestamp, "t0 has active timestamp");
        ok( $elems->[1]->get_active_timestamp, "t1 has active timestamp");
        ok( $elems->[2]->get_active_timestamp, "t2 has active timestamp");
        # XXX check only the first timestamp is returned
        ok(!$elems->[3]->get_active_timestamp,
           "t3 doesn't have active timestamp");
        ok(!$elems->[4]->get_active_timestamp,
           "t4 doesn't have active timestamp");
    },
);

test_parse(
    name => 'is_leaf()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* a
** b
*** c
* d
_
    num => 4,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        ok(!$elems->[0]->is_leaf, "a is not leaf");
        ok(!$elems->[1]->is_leaf, "b is not leaf");
        ok( $elems->[2]->is_leaf, "c is leaf");
        ok( $elems->[3]->is_leaf, "d is leaf");
    },
);

test_parse(
    name => 'promote_node() 1',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* h1
** h2
* h3
_
    num => 3,
    test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};
        my ($h1, $h2, $h3) = @$elems;

        $h1->promote_node;
        is($h1->level, 1, "level 1 won't be promoted further");

        $h2->promote_node;
        is($h2->level, 1, "level 2 becomes level 1 after being promoted");
        is($h2->as_string, "* h2\n", "_str reset after being promoted");
        is($h2->prev_sibling, $h1, "parent becomes sibling (1)");
        is($h2->next_sibling, $h3, "parent becomes sibling (2)");
    },
);
test_parse(
    name => 'promote_node() 2',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
** h1
** h2
** h3
_
    num => 3,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my ($h1, $h2, $h3) = @$elems;

        $h2->promote_node;
        ok(!$h2->next_sibling, "no more sibling after promote (2)")
            or diag explain $h2->next_sibling->as_string;
        is($h2->children->[0], $h3, "sibling becomes child");
    },
);
test_parse(
    name => 'promote_node() 3',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*** h1
_
    num => 1,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my ($h1) = @$elems;

        $h1->promote_node(2);
        is($h1->level, 1, "promote with argument, level 3 -> 1");
    },
);

test_parse(
    name => 'demote_node() 1',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* h1
* h2
* h3
_
    num => 3,
    test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};
        my ($h1, $h2, $h3) = @$elems;

        $h2->demote_node;
        is($h2->level, 2, "level 1 becomes level 2");
        is($h2->parent, $h1, "prev_sibling becomes parent");
        is($h1->next_sibling, $h3, "h1's next_sibling becomes h3");
        is($h3->prev_sibling, $h1, "h3's prev_sibling becomes h1");
    },
);
test_parse(
    name => 'demote_node() 2',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
* h1
_
    num => 1,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my ($h1) = @$elems;

        $h1->demote_node(3);
        is($h1->level, 4, "demote 3 means level 1 becomes 4");
    },
);

test_parse(
    name => 'promote_branch()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
** h1
*** h2
**** h3
*** h4
** h5
_
    num => 5,
    test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};
        my ($h1, $h2, $h3, $h4, $h5) = @$elems;

        $h1->promote_branch;
        is($h1->level, 1, "h1 becomes level 1");
        is($h2->level, 2, "h2 becomes level 2");
        is($h3->level, 3, "h3 becomes level 3");
        is($h4->level, 2, "h4 becomes level 2");
        is($h5->level, 2, "h5 stays at level 2");
    },
);

test_parse(
    name => 'demote_branch()',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
** h1
*** h2
**** h3
*** h4
** h5
_
    num => 5,
    test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};
        my ($h1, $h2, $h3, $h4, $h5) = @$elems;

        $h1->demote_branch;
        is($h1->level, 3, "h1 becomes level 3");
        is($h2->level, 4, "h2 becomes level 4");
        is($h3->level, 5, "h3 becomes level 5");
        is($h4->level, 4, "h4 becomes level 4");
        is($h5->level, 2, "h5 stays at level 2");
    },
);

test_parse(
    name => 'update_statistics_cookie()',
    filter_elements => sub { $_[0]->isa('Org::Element::Headline') },
    doc  => <<'_',
* 0 [1/2]
* 1 [50%]
* 2 [0/0]
** TODO a
** TODO b
** DONE c
*** TODO d
* 3 [0/0]
- [ ] item 1
- [X] item 2
- [X] item 3
  - [X] item 4
_
    num => 8,
    test_after_parse => sub {
        my (%args) = @_;
        my $doc    = $args{result};
        my $elems  = $args{elements};

        $_->update_statistics_cookie for @$elems;

        is_deeply($elems->[0]->statistics_cookie, "0/0");
        is_deeply($elems->[1]->statistics_cookie, "0%");
        is_deeply($elems->[2]->statistics_cookie, "1/3");
        is_deeply($elems->[7]->statistics_cookie, "2/3");
    },
);
done_testing();
