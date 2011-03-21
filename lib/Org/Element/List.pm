package Org::Element::List;
# ABSTRACT: Represent Org list

use 5.010;
use Moo;
extends 'Org::Element::Base';

=head1 ATTRIBUTES

=head2 indent

Indent (e.g. " " x 2).

=cut

has indent => (is => 'rw');

=head2 type

'U' for unordered (-, +, * for bullets), 'O' for ordered (1., 2., 3., and so
on). Alternatively you can look at the item's bullet to know which type the list
is.

=cut

has type => (is => 'rw');

=head2 bullet_style

E.g. '-', '*', '+'. For ordered list, currently just use '<N>.'

=cut

has bullet_style => (is => 'rw');


=head1 METHODS

=for Pod::Coverage

=cut

__END__

=head1 DESCRIPTION

Must have L<Org::Element::ListItem> (or another ::List) as children.

Derived from Org::Element::Base.

=cut
