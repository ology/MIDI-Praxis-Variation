package MIDI::Praxis::Variation;

# ABSTRACT: Variation techniques used in music composition

use strict;
use warnings;

our $VERSION = '0.0600';

use MIDI::Simple;

use Exporter 'import';

our @EXPORT = qw(
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
our %EXPORT_TAGS = (all => [qw(
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
)] );

=head1 SYNOPSIS

  use MIDI::Praxis::Variation ':all';

  my @notes = qw(C5 E5 G5);
  my @dura = qw(qn qn);

  my @x = augmentation(@dura);
  @x = diminution(@dura);
  my $x = dur('qn');
  @x = inversion('B4', @notes);
  $x = note_name_to_number('C5');
  @x = ntup(2, @notes);
  @x = original(@notes);
  $x = raugmentation(1.5, @dura);
  $x = rdiminution(1.5, @dura);
  @x = retrograde(@notes);
  @x = retrograde_inversion('B4', @notes);
  @x = transposition(@notes);
  $x = tye(@dura);

=head1 DESCRIPTION

Melodic variation techniques, as implemented here, expect an array of
MIDI::Simple style note names or durations as input. They return an
array of MIDI note numbers or duration values.

=head2 note_name_to_number

 Usage     : note_name_to_number($note_name)
 Purpose   : Map a single note name to a MIDI note number.
 Returns   : An equivalent MIDI note number or -1 if not
           : known.

 Comments  : Expects to see a MIDI::Simple style note name.

=cut

sub note_name_to_number {
    my ($in) = @_;

    return () unless $in;

    my $note_number = -1;

    if ($in =~ /^([A-Za-z]+)(\d+)/s) {    # E.g.,  "C3", "As4"
        $note_number = $MIDI::Simple::Note{$1} + $2 * 12
          if exists $MIDI::Simple::Note{$1};
    }

    return $note_number;
}


=head2 original

 Usage     : original(@array)
 Purpose   : Map note names to MIDI note numbers.
 Returns   : An equivalent array of MIDI note numbers.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names,
           : e.g.,  C5, Fs6, Bf3. It returns equivilent MIDI note
           : numbers leaving the array of note names untouched.

=cut

sub original {
    my @notes =  @_;

    return () unless @notes;

    my @ret = map { note_name_to_number($_) } @notes;

    return @ret;
}


=head2 retrograde

 Usage     : retrograde(@array)
 Purpose   : Form the retrograde of an array of note names.
 Returns   : The retrograde equivalent array as MIDI note numbers.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names.

=cut

sub retrograde {
    my @notes =  @_;

    my @ret = ();

    return () unless @notes;

    @ret = reverse original(@notes);

    return @ret;
}


=head2 transposition

 Usage     : transposition($distance, @array)
 Purpose   : Form the transposition of an array of notes.
 Returns   : MIDI note numbers equivalent by transposition from
           : an array of note names OR MIDI note numbers.

 Arguments : $distance - an integer giving distance and direction.
           : @array    - an array of note names OR MIDI note numbers.

 Comments  : Expects to see an integer followed an array of
           : MIDI::Simple style note names OR MIDI note numbers.
           : The integer specifies the direction and distance of
           : transposition. For example, 8 indicates 8 semitones
           : up while -7 asks for 7 semitones down. The array
           : argument specifies the notes to be transposed.

=cut

sub transposition {
    my ($delta, @notes) = @_;

    return () unless defined $delta && @notes;

    my @ret = ();

    if ($notes[0] =~ /[A-G]/) {
        @ret = original(@notes);
    }
    else {
        @ret = @notes;
    }

    for (@ret) {
        $_ += $delta;
    }

    return @ret;
}


=head2 inversion

 Usage     : inversion($axis, @array)
 Purpose   : Form the inversion of an array of notes.
 Returns   : MIDI note numbers equivalent by inversion to
           : an array of note names.

 Arguments : $axis  - A note to use as the axis of this inversion.
           : @array - An array of note names.

 Comments  : Expects to see a MIDI::Simple style note name.
           : followed by an array of such names. These give
           : the axis of inversion and the notes to be inverted.

=cut

sub inversion {
    my ($axis, @notes) = @_;

    return () unless $axis && @notes;

    my $center = note_name_to_number($axis);
    my $first  = note_name_to_number($notes[0]);
    my $delta  = $center - $first;

    my @transposed = transposition($delta, @notes);

    my @ret = map { 2 * $center - $_ } @transposed;

    return @ret;
}


=head2 retrograde_inversion

 Usage     : retrograde_inversion($axis, @array)
 Purpose   : Form the retrograde inversion of an array of notes.
 Returns   : MIDI note numbers equivalent by retrograde inversion to
           : an array of note names.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names.
           : Inverts about the supplied $axis.

=cut

sub retrograde_inversion {
    my ($axis, @notes) = @_; # A note name followed by an array of note names

    return () unless $axis && @notes;

    my @rev_notes = ();
    my @ret = ();

    @rev_notes = reverse @notes;

    @ret = inversion($axis, @rev_notes);

    return @ret;
}


=head2 dur

 Usage     : dur($dur_or_len)
 Purpose   : Compute duration of a note.
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected and integer output
           : is returned.

=cut

sub dur {
    my ($tempo, $arg) = (MIDI::Simple::Tempo, @_);

    return () unless $arg;

    my $dur = 0;

    if ($arg =~ /^d(\d+)$/) {   # numeric duration spec
        $dur = 0 + $1;
    }
    elsif (exists $MIDI::Simple::Length{$arg}) {   # length spec
        $dur = 0 + ($tempo * $MIDI::Simple::Length{$arg});
    }

    return $dur;
}


=head2 tye

 Usage     : tye($dur_or_len)
 Purpose   : Compute the sum of the durations of notes. As with a tie
           : in music notation. This odd spelling is used to avoid
           : conflict with the perl reserved word tie.

 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected and integer output
           : is returned.

=cut

sub tye {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my $sum = 0;

    for my $dura (@dur_or_len) {
        $sum += dur($dura);
    }

    return $sum;
}


=head2 raugmentation

 Usage     : raugmentation($ratio, $dur_or_len)
 Purpose   : Augment duration of a note multiplying it by $ratio.
 Returns   : Duration as an integer.

 Argument  : $ratio      - an integer multiplier
           : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned.

=cut

sub raugmentation {
    my ($ratio, $dur_or_len) = @_;

    return () unless $ratio && 1 < $ratio;
    return () unless $dur_or_len && length $dur_or_len;

    return dur($dur_or_len) * $ratio;
}


=head2 rdiminution

 Usage     : rdiminution($ratio, $dur_or_len)
 Purpose   : Diminish duration of a note dividing it by $ratio.
 Returns   : Duration as an integer.

 Argument  : $ratio      - an integer divisor
           : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned. This integer is the aproximate
           : result of dividing the original duration by $ratio.

=cut

sub rdiminution {
    my ($ratio, $dur_or_len) = @_;

    return () unless $ratio && 1 < $ratio && $dur_or_len;

    return sprintf '%.0f', dur($dur_or_len) / $ratio;
}


=head2 augmentation

 Usage     : augmentation($dur_or_len)
 Purpose   : Augment duration of a note multiplying it by 2,
           : (i.e., double it).
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned.

=cut

sub augmentation {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my @ret = ();

    for my $dura (@dur_or_len) {
        my $elem = 'd';
        $elem .= raugmentation(2, $dura);
        push @ret, $elem;
    }

    return @ret;
}


=head2 diminution

 Usage     : diminution($dur_or_len)
 Purpose   : Diminish duration of a note dividing it by 2,
           : (i.e., halve it).
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned. This integer is the approximate
           : result of dividing the original duration by 2.

=cut

sub diminution {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my @ret = ();

    for my $dura (@dur_or_len) {
        my $elem = 'd';
        $elem .= rdiminution(2, $dura);
        push @ret, $elem;
    }

    return @ret;
}


=head2 ntup

 Usage     : ntup($nelem, @subject)
 Purpose   : Catalog tuples of length $nelem in @subject.
 Returns   : An array of tuples of length $nelem.

 Argument  : $nelem      - number of elements in each tuple
           : @subject    - subject array to be scanned for tuples

 Comments  : Scan begins with the 0th element of @subject looking for
           : a tuple of length $nelem. Scan advances by one until it
           : has found all tuples of length $nelem. For example:
           : given the array @ar = qw( 1 2 3 4 ) and $nelem = 2
           : ntup(2, @ar) would return @ret = qw( 1 2 2 3 3 4 ). Note
           : that for $nelem == any of -1, 0, 5 using the same @ar as
           : its subject array ntup returns qw();

=cut

sub ntup {
    my ($n, @notes) = @_;

    return () unless $n && @notes;

    my @ret = ();

    if (@notes >= $n) {
        for my $index (0 .. @notes - $n) {
            push @ret, @notes[$index .. $index + $n - 1];
        }
    }

    return @ret;
}

=head1 SEE ALSO

The F<eg/*> and F<t/01-functions.t> files in this distribution

L<MIDI::Simple>

=head1 MAINTAINER

Gene Boggs <gene@cpan.org>

=cut

1;
