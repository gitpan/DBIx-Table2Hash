#!/usr/bin/perl
#
# Name:
#	test-table2hash.pl.
#
# Purpose:
#	Test DBIx::Table2Hash.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html
#
# Note:
#	tab = 4 spaces || die.

use strict;
use warnings;

use DBI;
use DBIx::Table2Hash;
use Error qw/:try/;
use FindBin;

# -----------------------------------------------

try
{
	my($dbh) = DBI -> connect
	(
		'DBI:mysql:test:127.0.0.1',
		'route',
		'bier',
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);
	
	# The evals protect against non-standard SQL
	# and against a non-existant table.
	
	eval{$dbh -> do('drop table if exists industry')};
	eval{$dbh -> do('drop table industry')};
	
	$dbh -> do('create table industry (industry_id int, industry_code char(1), industry_name varchar(255) )');
	
	my($input_file_name)	= $FindBin::Bin . '/industry.txt';
	my($sql)				= 'insert into industry (industry_id, industry_code, industry_name) values (?, ?, ?)';
	my($sth)				= $dbh -> prepare($sql);
	my($industry_id)		= 0;
	
	# Yes, we call die in the next statement, and the catch is triggered.
	# Try it, by corrupting the file name above.
	# That is, we don't need to say: || throw Error::Simple(...).
		
	open(INX, $input_file_name) || die("Can't open($input_file_name): $!");
	
	my($line);
	
	while ($line = <INX>)
	{
		$industry_id++;
		chomp($line);
		$sth -> execute($industry_id, split(/\t/, $line) );
	}
	
	$sth -> finish();
	
	close INX;
	
	my($href) = DBIx::Table2Hash -> new
	(
		dbh				=> $dbh,
		table_name		=> 'industry',
		key_column		=> 'industry_id',
	) -> select_hashref();
	
	for my $key (sort keys %$href)
	{
		print map{"Key: $key. Hash: $_ => $$href{$key}{$_}. \n"} sort keys %{$$href{$key} };
		print "\n";
	}
	
	my($h) = DBIx::Table2Hash -> new
	(
		dbh				=> $dbh,
		table_name		=> 'industry',
		key_column		=> 'industry_code',
		value_column	=> 'industry_name',
	) -> select();
	
	for my $key (sort keys %$h)
	{
		print "$key => $$h{$key}. \n";
		print "\n";
	}
}
catch Error::Simple with
{
	my($error) = $_[0] -> text();
	chomp($error);
	print "ES: ", $error;
};
