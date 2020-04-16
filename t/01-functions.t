#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'MIDI::Praxis::Variation', qw(
        augmentation
        diminution
        dur
        inversion
        note_name_to_number
        ntup
        original
        raugmentation
        rdiminution
        retrograde
        retrograde_inversion
        transposition
        tye
    );
}

my @got = augmentation();
my $expect = [];
is_deeply \@got, $expect, 'augmentation';

@got = augmentation('qn');
$expect = ['d192'];
is_deeply \@got, $expect, 'augmentation';

@got = augmentation('qn', 'qn');
$expect = ['d192', 'd192'];
is_deeply \@got, $expect, 'augmentation';

@got = diminution();
$expect = [];
is_deeply \@got, $expect, 'diminution';

@got = diminution('qn');
$expect = ['d48'];
is_deeply \@got, $expect, 'diminution';

@got = diminution('qn', 'qn');
$expect = ['d48', 'd48'];
is_deeply \@got, $expect, 'diminution';

done_testing();
