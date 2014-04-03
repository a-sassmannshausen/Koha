package C4::Housebound;

# Copyright 2011 Mark Gavillet
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
use C4::Context;
use base qw(Exporter);

our $VERSION = 3.02;
our @EXPORT  = qw(
  GetHouseboundDetails
  CreateHouseboundDetails
  UpdateHouseboundDetails
  GetCurrentHouseboundInstanceList
  GetHouseboundInstanceDetails
  UpdateHouseboundInstanceDetails
  CreateHouseboundInstanceDetails
  DeleteHouseboundInstanceDetails
  GetVolunteerNameAndID
  GetVolunteerList
  GetChooserList
  GetDelivererList
  CheckPrevIssue
);

=head1 NAME

C4::Housebound - Koha housebound patrons module.

=head1 SYNOPSIS

use C4::Housebound;

=head1 DESCRIPTION

This module contains routines for adding, modifying and deleting
housebound details for patrons, and instances of item delivery by
volunteers.

=head1 FUNCTIONS

=head2 GetHouseboundDetails

  $housebound = GetHouseboundDetails( $borrowernumber );

Return a hashref containing the housebound table's row associated with
$BORROWERNUMBER or undef.

=cut

sub GetHouseboundDetails {
    my ($borrowernumber) = @_;
    if ($borrowernumber) {
        my $dbh = C4::Context->dbh;
        return $dbh->selectrow_hashref(
            'select * from housebound where borrowernumber=?',
            {}, $borrowernumber );
    }
    return;
}

=head2 CreateHouseboundDetails

  CreateHouseboundDetails( $borrowernumber, $day, $frequency,
                           $Itype_quant, $Item_subject, $Item_authors,
                           $referral, $notes );

Create a new entry in the housebound table containing our arguments.
The return value is undef.

=cut

sub CreateHouseboundDetails {
    my ( $borrowernumber, $day, $frequency, $Itype_quant, $Item_subject,
        $Item_authors, $referral, $notes )
      = @_;
    if ($borrowernumber) {
        my $dbh = C4::Context->dbh;
        my $sth = $dbh->prepare(
'insert into housebound (day, frequency, borrowernumber, Itype_quant, Item_subject, Item_authors, referral, notes) values (?,?,?,?,?,?,?,?)'
        );
        $sth->execute( $day, $frequency, $borrowernumber, $Itype_quant,
            $Item_subject, $Item_authors, $referral, $notes );
    }
    return;
}

=head2 UpdateHouseboundDetails

  UpdateHouseboundDetails( $hbnumber, $borrowernumber, $day,
                           $frequency, $Itype_quant, $Item_subject,
                           $Item_authors, $referral, $notes );

Update housebound table's row matching $hbnumber with our arguments.
The return value is undef.

=cut

sub UpdateHouseboundDetails {
    my (
        $hbnumber,     $borrowernumber, $day,
        $frequency,    $Itype_quant,    $Item_subject,
        $Item_authors, $referral,       $notes
    ) = @_;
    if ($hbnumber) {
        my $dbh = C4::Context->dbh;
        my $sth = $dbh->prepare(
'update housebound set day=?,frequency=?,borrowernumber=?,Itype_quant=?,Item_subject=?,Item_authors=?,referral=?,notes=? where hbnumber=?'
        );
        $sth->execute(
            $day,         $frequency,    $borrowernumber,
            $Itype_quant, $Item_subject, $Item_authors,
            $referral,    $notes,        $hbnumber
        );
    }
    return;
}

=head2 GetCurrentHouseboundInstanceList

  $hb_instances = GetCurrentHouseboundInstanceList( $borrowernumber );

Return an arrayref containing all Housebound_Instances associated with
$BORROWERNUMBER, or undef.

=cut

sub GetCurrentHouseboundInstanceList {
    my ($borrowernumber) = @_;
    if ($borrowernumber) {
        my $dbh = C4::Context->dbh;
        my $sql =<<'END_SQL';
SELECT housebound_instance . * , concat( volunteer.firstname, ' ', volunteer.surname ) AS vol,
 concat(chooser.firstname, ' ', chooser.surname) as cho,
 concat(deliverer.firstname, ' ', deliverer.surname) as del
 FROM housebound_instance
 left JOIN borrowers volunteer ON volunteer.borrowernumber = housebound_instance.volunteer
 left join borrowers chooser on chooser.borrowernumber = housebound_instance.chooser
 left join borrowers deliverer on deliverer.borrowernumber = housebound_instance.deliverer
 where housebound_instance.borrowernumber=?
 order by housebound_instance.dmy desc
END_SQL
          return $dbh->selectall_arrayref( $sql, { Slice => {} },
            $borrowernumber );
    }
    return;
}

=head2 GetVolunteerNameAndID

  $volunteer = GetVolunteerNameAndID( $borrowernumber );

Return a hashref containing details of the volunteer identified by
$BORROWERNUMBER, or undef.

=cut

sub GetVolunteerNameAndID {
    my ($borrowernumber) = @_;
    if ($borrowernumber) {
        my $dbh = C4::Context->dbh;
        return $dbh->selectrow_hashref(
'select borrowernumber,title,firstname,surname from borrowers where borrowernumber=?',
            {}, $borrowernumber
        );
    }
    return;
}

=head2 GetVolunteerList

  $volunteers = GetVolunteerList();

Return an arrayref containing borrowernumbers and names of all known
volunteers, or undef.

=cut

sub GetVolunteerList {
    return GetHouseboundList("VOL");
}

=head2 GetDelivererList

  $deliverers = GetDelivererList();

Return an arrayref containing borrowernumbers and names of all known
deliverers, or undef.

=cut

sub GetDelivererList {
    return GetHouseboundList("DELIV");
}

=head2 GetChooserList

  $choosers = GetChooserList();

Return an arrayref containing borrowernumbers and names of all known
choosers, or undef.

=cut

sub GetChooserList {
    return GetHouseboundList("CHO");
}

=head2 GetHouseboundList

  $patrons = GetHouseboundList( $brw_cat_code );

Return an arrayref containing borrowernumbers and names of all
borrowers with $BRW_CAT_CODE, or undef.

=cut

sub GetHouseboundList {
    my ( $cat_code ) = @_;
    my $dbh = C4::Context->dbh;
    my $sql = "SELECT borrowernumber as volbornumber,
 concat(title, ' ', firstname, ' ', surname) as fullname
 from borrowers where categorycode=?
 order by surname, firstname asc";
      return $dbh->selectall_arrayref( $sql, { Slice => {} }, $cat_code );
}

=head2 GetHouseboundInstanceDetails

  $housebound = GetHouseboundInstanceDetails( $instance_id );

Return a hashref containing all details of the housebound_instance
associated with $INSTANCE_ID or undef.

=cut

sub GetHouseboundInstanceDetails {
    my ($instanceid) = @_;
    if ($instanceid) {
        my $dbh = C4::Context->dbh;
        return $dbh->selectrow_hashref(
            'SELECT * from housebound_instance where instanceid=?',
            {}, $instanceid );
    }
    return;
}

=head2 UpdateHouseboundInstanceDetails

  UpdateHouseboundInstanceDetails( $instanceid, $hbnumber, $dmy,
                                   $time, $borrowernumber, $volunteer,
                                   $chooser, $deliverer );

Update housebound_instance table's row matching $instanceid with our
arguments. The return value is undef.

=cut

sub UpdateHouseboundInstanceDetails {
    my ( $instanceid, $hbnumber, $dmy, $time, $borrowernumber, $volunteer,
        $chooser, $deliverer )
      = @_;
    if ($hbnumber) {
        my $dbh = C4::Context->dbh;
        my $sth = $dbh->prepare(
'update housebound_instance set hbnumber=?, dmy=?, time=?, borrowernumber=?, volunteer=?, chooser=?, deliverer=? where instanceid=?'
        );
        $sth->execute( $hbnumber, $dmy, $time, $borrowernumber, $volunteer,
            $chooser, $deliverer, $instanceid );
    }
    return;
}

=head2 CreateHouseboundInstanceDetails

  CreateHouseboundInstanceDetails( $hbnumber, $dmy, $time,
                                   $borrowernumber, $volunteer,
                                   $chooser, $deliverer );

Create a new housebound_instance table row containing our
arguments. The return value is undef.

=cut

sub CreateHouseboundInstanceDetails {
    my ( $hbnumber, $dmy, $time, $borrowernumber, $volunteer, $chooser,
        $deliverer )
      = @_;
    if ($borrowernumber) {
        my $dbh = C4::Context->dbh;
        my $sth = $dbh->prepare(
'insert into housebound_instance (hbnumber, dmy, time, borrowernumber, volunteer, chooser, deliverer) values (?,?,?,?,?,?,?)'
        );
        $sth->execute( $hbnumber, $dmy, $time, $borrowernumber, $volunteer,
            $chooser, $deliverer );
    }
    return;
}

=head2 DeleteHouseboundInstanceDetails

  DeleteHouseboundInstanceDetails( $instanceid );

Delete the row from housebound_instance identified by
$INSTANCEID. The return value is undef.

=cut

sub DeleteHouseboundInstanceDetails {
    my ($instanceid) = @_;
    if ($instanceid) {
        my $dbh = C4::Context->dbh;
        my $sth =
          $dbh->prepare('delete from housebound_instance where instanceid=?');
        $sth->execute($instanceid);
    }
    return;
}

=head2 CheckPrevIssue

  CheckPrevIssue( $borrowernumber, $biblionumber );

Return 1 if $BIBLIONUMBER has previously been issued to
$BORROWERNUMBER, 0 otherwise.

=cut

sub CheckPrevIssue {
    my ( $borrowernumber, $biblionumber ) = @_;
    my $dbh       = C4::Context->dbh;
    my $previssue = 0;
    my $sth =
      $dbh->prepare('select itemnumber from items where biblionumber=?');
    $sth->execute($biblionumber);

    my $query = $dbh->prepare(
'select count(itemnumber) from old_issues where borrowernumber=? and itemnumber=?'
    );
    while ( my @row = $sth->fetchrow_array() ) {
        $query->execute( $borrowernumber, $row[0] );
        while ( my @matches = $query->fetchrow_array() ) {
            if ( $matches[0] > 0 ) {
                $previssue = 1;
            }
        }
    }
    return $previssue;
}

1;

__END__

=head1 AUTHOR

Mark Gavillet
Alex Sassmannshausen

=cut
