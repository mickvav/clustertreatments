#!/usr/bin/perl

use strict;
use utf8;
use XML::Parser;
use Data::Dumper;
use Encode qw/ decode /;
use DBI;
use Algorithm::KMeans;


my $dsn = "DBI:mysql:database=patients;host=localhost";
my $dbh = DBI->connect($dsn, "debian-sys-maint", "abUYOCiQVq7CMTmp");

$dbh->do("DROP TABLE EhrInspectionCluster;");

$dbh->do("CREATE TABLE `EhrInspectionCluster` (
`EhrInspectionID` int(11) not null,
`ComplCluster` int(11) default null,
`DiagnosisCluster` int(11) default null,
`TreatmentCluster` int(11) default null,
PRIMARY KEY(`EhrInspectionID`) ) ENGINE=InnoDB;");


my $ary_ref  = $dbh->selectall_arrayref("SELECT EhrInspectionID,FieldID,AxeID,Count FROM EhrInspectionVector ORDER BY EhrInspectionID,FieldID,AxeID ");

open(FD1,">ComplCluster.txt");
open(FD2,">DiagnosisCluster.txt");
open(FD3,">TreatmentCluster.txt");

my $N=200;

my $eid= undef;
my @Compl = map { 0 } (0 .. $N-1);
my @Diag  = map { 0 } (0 .. $N-1);
my @Treat = map { 0 } (0 .. $N-1);

foreach my $row (@{$ary_ref} ) {
   if(not(defined($eid))) {
      $eid=$row->[0];
   } elsif($eid != $row->[0]) {
      print FD1 $eid."\t".join("\t",@Compl)."\n";
      print FD2 $eid."\t".join("\t",@Diag)."\n";
      print FD3 $eid."\t".join("\t",@Treat)."\n";
      @Compl = map { 0 } (0 .. $N-1);
      @Diag  = map { 0 } (0 .. $N-1);
      @Treat = map { 0 } (0 .. $N-1);
      $eid = $row->[0];
   }; 
   my($e,$FieldID,$AxeID,$Count) = @{$row};
   if($FieldID>=1 and $FieldID <=3) {
      $Compl[$AxeID]+=$Count;
   };
   if($FieldID==4) {
      $Diag[$AxeID]+=$Count;
   };
   if($FieldID==5) {
      $Treat[$AxeID]+=$Count;
   };
};

close(FD1);
close(FD2);
close(FD3);

my $mask = "N".("1" x $N);

foreach my $datafile ("ComplCluster.txt","DiagnosisCluster.txt","TreatmentCluster.txt") {

my $clusterer = Algorithm::KMeans->new( datafile        => $datafile,
                                          mask            => $mask,
                                          K               => 0,
                                          cluster_seeding => 'random',
                                          terminal_output => 1,
                                          write_clusters_to_files => 1,
                                        );


$clusterer->read_data_from_file();
my ($clusters_hash, $cluster_centers_hash) = $clusterer->kmeans();

  my $column = $datafile;
  $column =~s/.txt$//;

  
  $dbh->do("INSERT INTO EhrInspectionCluster (EhrInspectionID,$column) VALUES ".
       join(",",
           map { "(".$_.",".$clusters_hash->{$_}.")" } 
               keys(%{$clusters_hash}) 
           )." ON DUPLICATE KEY UPDATE $column=VALUES($column) "
          );

};
