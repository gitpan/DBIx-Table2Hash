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

use Carp;

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
our $VERSION = '1.10';

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

	croak(__PACKAGE__ . '. You must supply a value for the parameters dbh, key_column and table_name')
		if (! ($$self{'_dbh'} && $$self{'_key_column'} && $$self{'_table_name'}) );

	return $self;

}	# End of new.

# -----------------------------------------------

sub select
{
	my($self)	= @_;

	croak(__PACKAGE__ . '. You must supply a value for the parameter value_column')
		if (! $$self{'_value_column'});

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

sub select_hashref
{
	my($self)	= @_;
	my($sql)	= "select * from $$self{'_table_name'} $$self{'_where'}";
	my($sth)	= $$self{'_dbh'} -> prepare($sql);

	$sth -> execute();

	my($data, %h);

	while ($data = $sth -> fetchrow_hashref() )
	{
		$h{$$data{$$self{'_key_column'} } } = {%$data} if (defined $$data{$$self{'_key_column'} });
	}

	\%h;

}	# End of select_hashref.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Table2Hash> - Read a database table into a hash

=head1 Synopsis

	#!/usr/bin/perl

	my($key2value) = DBIx::Table2Hash -> new
	(
		dbh          => $dbh,
		table_name   => $table_name,
		key_column   => 'name',
		value_column => 'id'
	) -> select();
	# or
	my($key2hashref) = DBIx::Table2Hash -> new
	(
		dbh          => $dbh,
		table_name   => $table_name,
		key_column   => 'name',
	) -> select_hashref();

=head1 Description

C<DBIx::Table2Hash> is a pure Perl module.

This module reads a database table and stores keys and values in a hash. The resultant hash is not nested in any way.

The aim is to create a hash which is a simple look-up table. To this end, the module allows the key_column to point to
an SQL expression.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Table2Hash> object.

This is the class's contructor.

Parameters:

=over 4

=item *

dbh

A database handle.

This parameter is mandatory.

=item *

table_name

The name of the table to select from.

This parameter is mandatory.

=item *

key_column

The name of the column, or SQL expression, to use for hash keys.

Say you have 2 columns, called col_a and col_b. Then you can concatenate them with:

key_column => 'concat(col_a, col_b)'

or, even fancier,

key_column => "concat(col_a, '-', col_b)"

This parameter is mandatory.

=item *

value_column

The name of the column to use for hash values.

This parameter is mandatory if you are going to call select(), and optional if you are going to call
select_hashref().

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

Each key in the hash points to a single value.

The demo program test-table2hash.pl, in the examples/ directory, calls select().

=head1 Method: select_hashref()

Returns a hash ref.

Calling select_hashref() actually executes the SQL select statement, and builds the hash.

Each key in the hash points to a hashref.

The demo program test-table2hash.pl, in the examples/ directory, calls select_hashref().

=head1 Required Modules

Only those shipped with Perl.

=head1 Changes

See Changes.txt.

=head1 FAQ

Q: What is the point of this module?

A: To be able to restore a hash from a database rather than from a file.

Q: Can your other module C<DBIx::Hash2Table> be used to save the hash back to the database?

A: Sure.

Q: Do you ship a complete demo, which loads a table and demonstrates the 2 methods select() and select_hashref()?

A: Yes. See the examples/ directory.

If you installed this module locally via ppm, look in the x86/ directory for the file to unpack.

If you installed this module remotely via ppm, you need to download and unpack the distro itself.

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
