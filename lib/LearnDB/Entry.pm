package LearnDB::Entry;

use strict;
use warnings;

use overload fallback => 1,
  '""' => sub { shift()->description() };

sub wrap {
  my ($cls, $obj) = @_;
  return $obj if ref($obj) eq $cls;
  $cls->new(term => '', index => -1, count => -1, value => $obj)
}

sub new {
  my ($cls, %opt) = @_;
  bless \%opt, $cls
}

sub original_term {
  shift()->{original_term}
}

sub corrected_term {
  shift()->{corrected_term}
}

sub bare {
  my $self = shift;
  $self->term() eq '' || $self->value() =~ /^\s*: /
}

sub strip_value {
  my ($self, $value) = @_;
  $value =~ s/^\s*: //;
  $value
}

sub template {
  my $self = shift();
  $self->bare() ? $self->formatted_value() : $self->description()
}

sub term {
  shift()->{term}
}

sub value {
  shift()->{value}
}

=item $entry->with_new_value('newvalue')
Returns a new entry with the supplied value. $entry is unmodified.
=cut
sub with_new_value {
  my ($self, $newvalue) = @_;
  ref($self)->new(%$self, value => $newvalue)
}

sub with_prop {
  my ($self, %props) = @_;
  ref($self)->new(%$self, %props)
}

sub prop {
  my ($self, $prop) = @_;
  $self->{$prop}
}

sub formatted_value {
  my $self = shift;
  $self->strip_value($self->value())
}

sub index {
  shift()->{index}
}

sub count {
  shift()->{count}
}

sub description {
  my $self = shift;
  my ($term, $index, $count, $value) = ($self->term(), $self->index(),
                                        $self->count(), $self->value());
  return $value if $term eq '';

  my $original_term = $self->original_term();
  my $corrected_term = $self->corrected_term();
  if ($original_term && $term) {
    undef $corrected_term if lc($corrected_term) eq lc($term);
    my @prelude = grep($_, ($original_term, $corrected_term));
    $term = join(" ~ ", @prelude, $term);
  }
  "$term\[$index/$count]: $value"
}

1
