package DBIx::Table2Hash;

# Name:
#	DBIx::Table2Hash.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;

use CGI;

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Hash2Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.00';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_dbh			=> '',
		_key_column		=> '',
		_table_name		=> '',
		_value_column	=> '',
		_where			=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub new
{
	my($caller, %arg)		= @_;
	my($caller_is_obj)		= ref($caller);
	my($class)				= $caller_is_obj || $caller;
	my($self)				= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		elsif ($caller_is_obj)
		{
			$$self{$attr_name} = $$caller{$attr_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	croak(__PACKAGE__ . ". You must supply a value for each parameter except 'where'")
		if (! ($$self{'_dbh'} && $$self{'_key_column'} && $$self{'_table_name'} && $$self{'_value_column'}) );

	return $self;

}	# End of new.

# -----------------------------------------------

sub select
{
	my($self)	= @_;
	my($sql)	= "select $$self{'_key_column'}, $$self{'_value_column'} from $$self{'_table_name'} $$self{'_where'}";
	my($sth)	= $$self{'_dbh'} -> prepare($sql);

	$sth -> execute();

	my($data, %h);

	while ($data = $sth -> fetch() )
	{
		$h{$$data[0]} = $$data[1] if (defined $$data[0]);
	}

	\%h;

}	# End of select.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Table2Hash> - Read a database table into a hash

=head1 Version

This document refers to version 1.00 of C<DBIx::Table2Hash>, released 8-Jan-2003.

=head1 Synopsis

	#!/usr/bin/perl

	my($hash_ref) = DBIx::Table2Hash -> new
	(
		dbh          => $dbh,
		table_name   => $table_name,
		key_column   => 'name',
		value_column => 'id'
	) -> select();

=head1 Description

C<DBIx::Table2Hash> is a pure Perl module.

This module reads a database table and stores keys and values in a hash. The resultant hash is not nested in any way.

The aim is to create a hash which is a simple look-up table. To this end, the module allows the key_column to point to
an SQL expression.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Table2Hash> object.

This is the class's contructor.

Parameters:

=over 4

=item *

dbh

A database handle.

=item *

table_name

The name of the table to select from.

=item *

key_column

The name of the column, or SQL expression, to use for hash keys.

Say you have 2 columns, called col_a and col_b. Then you can concatenate them with:

key_column => 'concat(col_a, col_b)'

or, even fancier,

key_column => "concat(col_a, '-', col_b)"

=item *

value_column

The name of the column to use for hash values.

=item *

where

The optional where clause, including the word 'where', to add to the select.

=back

=head1 Method: new(...)

Returns a object of type C<DBIx::Table2Hash>.

See above, in the section called 'Constructor and initialization'.

=head1 Method: select()

Returns a hash ref.

Calling select() actually executes the SQL select statement, and builds the hash.

=head1 Required Modules

DBI, so you can provide a database handle.

=head1 Changes

See Changes.txt.

=head1 FAQ

Q: What is the point of this module?

A: To be able to restore a hash from a database rather than from a file.

Q: Can your other module C<DBIx::Hash2Table> be used to save the hash back to the database?

A: Sure.

Q: Are there any other modules with similar capabilities?

A: Yes:

=over 4

=item *

C<DBIx::Lookup::Field>

Quite similar.

=item *

C<DBIx::TableHash>

This module takes a very long set of parameters, but unfortunately does not take a database handle.

It does mean the module, being extremely complex, can read in more than one column as the value of a hash key, and it
has caching abilities too.

It works by tieing a hash to an MySQL table, and hence supports writing to the table. It uses MySQL-specific code,
for example, when it locks tables.

Unfortunately, it does not use data binding, so it cannot handle data which contains single quotes!

Further, it uses /^\w+$/ to 'validate' column names, so it cannot accept an SQL expression instead of a column name.

Lastly, it also uses /^\w+$/ to 'validate' table names, so it cannot accept table names and views containing spaces
and other 'funny' characters, eg '&' (both of which I have to deal with under MS Access).

=item *

C<DBIx::Tree>

This module is more like the inverse of C<DBIx::Hash2Table>, in that it assumes you are building a nested hash.

As it reads the database table it calls a call-back sub, which you use to process the rows of the table.

=back

=head1 Author

C<DBIx::Table2Hash> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2003.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2003, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
