#!/usr/bin/perl
use strict;
use warnings;

use C4::Context;
use Test::More tests => 29;
use Test::MockModule;
use DBD::Mock;

use_ok('C4::Housebound');

# Setup mock db
my $module_context = new Test::MockModule('C4::Context');
$module_context->mock(
    '_new_dbh',
    sub {
        my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
          || die "Cannot create handle: $DBI::errstr\n";
        return $dbh;
    }
);

my $dbh = C4::Context->dbh();

# convenience variables
my $name;
# mock_add_resultset vars
my ( $sql, $sql2, @bound_params, @keys, @values, %result ) = ( );
# mock_history_verification vars
my ( $history, $params, $query ) = ( );

sub clean_vars() {
    ( $name, $sql, $sql2, @bound_params, @keys, @values, %result,
      $history, $params, $query ) = ( );
    $dbh->{mock_clear_history} = 1;
}

# Tests
## GetHouseboundDetails
$name         = 'GetHouseboundDetails';
$sql          = 'select * from housebound where borrowernumber=?';
@bound_params = ( 101 );
@keys         = qw< hbnumber day frequency borrowernumber Itype_quant
                    Item_subject Item_authors referral notes >;
@values       = qw< 5 Monday Week-2/4 101 books dvd thrillers cooke
                    alex none >;
foreach my $i ( 0 .. $#keys) {
    $result{$keys[$i]} = $values[$i];
}

is( GetHouseboundDetails('unknown'), undef,
    $name . ': Return value "undefined".' );

$dbh->{mock_add_resultset} =
  {
   sql          => $sql,
   bound_params => [ @bound_params ],
   results      => [ [ @keys ], [ @values ] ],
  };

is_deeply( GetHouseboundDetails($bound_params[0]), \%result,
           $name . ': Return value "$result".' );

clean_vars();

## CreateHouseboundDetails
$name      = 'CreateHouseboundDetails';
$sql       = 'insert into housebound'
  . ' (day, frequency, borrowernumber, Itype_quant, Item_subject,'
  . ' Item_authors, referral, notes) values (?,?,?,?,?,?,?,?)';
@keys      = qw< day frequency borrowernumber Itype_quant Item_subject
                 Item_authors referral notes >;
@values    = qw< Tuesday Week-3/4 103 journals psychology sam bob $name >;

is( CreateHouseboundDetails($values[2], $values[0], $values[1], $values[3],
                            $values[4], $values[5], $values[6], $values[7]),
    undef, $name . ': Return value "undefined".');

$history = $dbh->{mock_all_history};
$query = $history->[0];
$params = $query->bound_params;

is($query->statement, $sql, $name . ': Correct statement generated' );
is(scalar(@{$params}), scalar(@values),
   $name . ': Correct number of parameters bound.' );
is_deeply( $params, \@values,
           $name . ': Correct parameter values passed.' );

clean_vars();

## UpdateHouseboundDetails
$name = 'UpdateHouseboundDetails';
$sql  = 'update housebound set day=?,frequency=?,borrowernumber=?,'
  . 'Itype_quant=?,Item_subject=?,Item_authors=?,referral=?,notes=?'
  . ' where hbnumber=?',
@keys      = qw< day frequency borrowernumber Itype_quant Item_subject
                 Item_authors referral notes hbnumber>;
@values    = qw< Tuesday Week-3/4 103 journals psychology sam bob $name 1>;
is( UpdateHouseboundDetails( $values[8], $values[2], $values[0], $values[1],
                             $values[3], $values[4], $values[5], $values[6],
                             $values[7] ),
    undef, $name . ': Return value "undefined".');

$history = $dbh->{mock_all_history};
$query = $history->[0];
$params = $query->bound_params;

is($query->statement, $sql, $name . ': Correct statement generated' );
is(scalar(@{$params}), scalar(@values),
   $name . ': Correct number of parameters bound.');
is_deeply( $params, \@values,
           $name . ': Correct parameter values passed.');

clean_vars();

## GetCurrentHouseboundInstanceList
### GetcurrentHouseboundInstanceList's Slice causes
### mock dbd to fail
### Cannot test.

## GetVolunteerNameAndID
$name         = "GetVolunteerNameAndID";
$sql          = 'select borrowernumber,title,firstname,surname'
  . ' from borrowers where borrowernumber=?';
@bound_params = ( 101 );
@keys      = qw< borrowernumber title firstname surname >;
@values    = qw< 101 Mr John Doe >;
foreach my $i ( 0 .. $#keys) {
    $result{$keys[$i]} = $values[$i];
}

is( GetVolunteerNameAndID($bound_params[0]), undef,
    $name . ': Return value "undefined".' );

$dbh->{mock_add_resultset} =
  {
   sql          => $sql,
   bound_params => [ @bound_params ],
   results      => [ [ @keys ], [ @values ] ],
  };

is_deeply( GetVolunteerNameAndID($bound_params[0]),
           \%result, $name . ': Return value "$result".' );

clean_vars();

## GetVolunteerList
### GetVolunteerList's Slice causes mock dbd to fail
### Cannot test.

## GetHouseboundInstanceDetails
$name         = 'GetHouseboundInstanceDetails';
$sql          = 'SELECT * from housebound_instance where instanceid=?';
@bound_params = ( 1 );
@keys      = qw< instanceid hbnumber dmy time borrowernumber volunteer
                 chooser deliverer >;
@values    = qw< 1 5 2014-03-31 am 101 102 103 104 >;
foreach my $i ( 0 .. $#keys) {
    $result{$keys[$i]} = $values[$i];
}

is( GetHouseboundInstanceDetails('1'), undef,
    $name . ': Return value "undefined".' );

$dbh->{mock_add_resultset} =
  {
   sql          => $sql,
   bound_params => [ @bound_params ],
   results      => [ [ @keys ], [ @values ] ],
  };

is_deeply( GetHouseboundInstanceDetails('1'), \%result,
           $name . ': Return value "$result".' );

clean_vars();

## UpdateHouseboundInstanceDetails
$name      = "UpdateHouseboundInstanceDetails";
$sql       = 'update housebound_instance set hbnumber=?, dmy=?,'
  . ' time=?, borrowernumber=?, volunteer=?, chooser=?, deliverer=?'
  . ' where instanceid=?';
@keys      = qw< hbnumber dmy time borrowernumber volunteer chooser
                 deliverer instanceid >;
@values    = qw< 5 2014-03-31 am 101 102 103 104 1 >;

is( UpdateHouseboundInstanceDetails( $values[7], $values[0], $values[1],
                                     $values[2], $values[3], $values[4],
                                     $values[5], $values[6] ), undef,
    $name . ': Return value "undefined".' );

$history = $dbh->{mock_all_history};
$query = $history->[0];
$params = $query->bound_params;

is($query->statement, $sql, $name . ': Correct statement generated' );
is(scalar(@{$params}), scalar(@values),
   $name . ': Correct number of parameters bound.');
is_deeply( $params, \@values,
           $name . ': Correct parameter values passed.');

clean_vars();

## CreateHouseboundInstanceDetails
$name      = "CreateHouseboundInstanceDetails";
$sql       = 'insert into housebound_instance'
  . ' (hbnumber, dmy, time, borrowernumber, volunteer, chooser, deliverer)'
  . ' values (?,?,?,?,?,?,?)';
@keys      = qw< hbnumber dmy time borrowernumber volunteer chooser
                 deliverer >;
@values    = qw< 5 2014-03-31 am 101 102 103 104 >;

is( CreateHouseboundInstanceDetails( @values ), undef,
    $name . ': Return value "undefined".');

$history = $dbh->{mock_all_history};
$query = $history->[0];
$params = $query->bound_params;

is($query->statement, $sql, $name . ': Correct statement generated' );
is(scalar(@{$params}), scalar(@values),
   $name . ': Correct number of parameters bound.' );
is_deeply( $params, \@values,
           $name . ': Correct parameter values passed.' );

$dbh->{mock_clear_history} = 1;

## DeleteHouseboundInstanceDetails
$name      = 'DeleteHouseboundInstanceDetails';
$sql       = 'delete from housebound_instance where instanceid=?';
@keys      = qw< instanceid >;
@values    = qw< 1 >;

is( DeleteHouseboundInstanceDetails( @values ), undef,
    $name . ': Return value "undefined".');

$history = $dbh->{mock_all_history};
$query = $history->[0];
$params = $query->bound_params;

is($query->statement, $sql, $name . ': Correct statement generated' );
is(scalar(@{$params}), scalar(@values),
   $name . ': Correct number of parameters bound.' );
is_deeply( $params, \@values,
           $name . ': Correct parameter values passed.' );

clean_vars();

## CheckPrevIssue
$name      = 'CheckPrevIssue';
$sql       = 'select itemnumber from items where biblionumber=?';
$sql2      = 'select count(itemnumber) from old_issues'
  . ' where borrowernumber=? and itemnumber=?';
@keys      = qw< borrowernumber biblionumber itemnumber >;
@values    = qw< 101 3576 5043 >;

# 1) Prepop items with itemnumber for result
$dbh->{mock_add_resultset} = {
    sql          => $sql,
    bound_params => $keys[1],
    results      => [ [ ( $keys[2] ) ], [ ( $values[2] ) ] ],
   };
# 2) Test if never issued before (expect 0)
is( CheckPrevIssue( $keys[0], $keys[1] ), 0,
    $name . ': Return value "no matches".' );
# 3) Prepop old_issues with itemnumber and borrowernumber
$dbh->{mock_add_resultset} = {
    sql          => $sql2,
    bound_params => [ $keys[0], $keys[2] ],
    results      => [
                     [ ( $keys[0], $keys[2] ) ],
                     [ ( $values[0], $values[2] ) ],
                     [ ( $values[0], $values[2] ) ],
                     [ ( $values[0], $values[2] ) ],
                     [ ( $values[0], $values[2] ) ],
                    ],
   };
# 4) Test if issued before (e.g. 7 times — expect 1)
is( CheckPrevIssue( $keys[0], $keys[1] ), 1,
    $name . ': Return value "> 0 matches".' );

clean_vars();
