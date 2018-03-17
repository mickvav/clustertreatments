#!/usr/bin/perl

use strict;
use utf8;
use XML::Parser;
use Data::Dumper;
use Encode qw/ decode /;
use DBI;

my $dsn = "DBI:mysql:database=patients;host=localhost";
my $dbh = DBI->connect($dsn, "debian-sys-maint", "abUYOCiQVq7CMTmp");

$dbh->do("DROP TABLE EhrInspectionVector;");
$dbh->do("CREATE TABLE `EhrInspectionVector` (
`EhrInspectionID` int(11) not null,
`FieldID` int(11) not null,
`AxeID` int(11) not null,
`Count` int(11) not null,
PRIMARY KEY(`EhrInspectionID`,`FieldID`,`AxeID`) ) ENGINE=InnoDB;");

sub load_wordclasses($) {
  my %wc=();
  open(FD,"<".$_[0]) or die "Can't open file ".$_[0];
  binmode(FD,":utf8");
  while(<FD>) {
     chomp;
     my ($w,$c) = split(/\s/);
     if($c=~/^\d+$/) {
        $wc{$w}=$c;
     };
  };
  close(FD);
  return \%wc;

};

sub classify_text($$) {
  
  my @words = split(/[\s,\.\n]+/,$_[0]);
  my $wc=$_[1];
  my %res=();
  foreach my $w (@words) {
    my $c=$wc->{$w};
    if(defined($c)) { 
       $res{$c} ++ ;
    };
  };
  return \%res;
};

sub push_res($$$) {
  my ($id,$f,$res) = @_;
     my $line = "INSERT INTO EhrInspectionVector (EhrInspectionID,FieldID,AxeID,Count) VALUES ".
          join(",", 
             map { 
                 "(".$id.",".$f.",".$_.",".$res->{$_}.")"; } keys(%{$res}) 
              );
    if($line!~/VALUES $/) {
      my $n=$dbh->do($line);
      if ( $n <= 0 ) { 
         print $line;
         exit(1);
      } else { return $n ; };
    } else { return 0; };
};

my $wc_complaints = load_wordclasses("complaints..word2vec.txt");
my $wc_diagnosis = load_wordclasses("diagnosis..word2vec.txt");
my $wc_treatments = load_wordclasses("treatments..word2vec.txt");

my $hash_ref = $dbh->selectall_hashref("SELECT EhrInspectionID,ComplaintsRTF,AnamnesisRTF,ObjectiveFindingsRTF,TreatmentRTF,DiagnosRTF FROM EhrInspection", "EhrInspectionID");

foreach my $k (keys(%{$hash_ref})) {
    my $res=classify_text($hash_ref->{$k}->{ComplaintsRTF},$wc_complaints);
    push_res($hash_ref->{$k}->{EhrInspectionID},1,$res); 
            
    my $res=classify_text($hash_ref->{$k}->{AnamnesisRTF},$wc_complaints);
    push_res($hash_ref->{$k}->{EhrInspectionID},2,$res); 

    my $res=classify_text($hash_ref->{$k}->{ObjectiveFindingsRTF},$wc_complaints);
    push_res($hash_ref->{$k}->{EhrInspectionID},3,$res); 

    my $res=classify_text($hash_ref->{$k}->{TreatmentRTF},$wc_treatments);
    push_res($hash_ref->{$k}->{EhrInspectionID},4,$res); 

    my $res=classify_text($hash_ref->{$k}->{DiagnosRTF},$wc_diagnosis);
    push_res($hash_ref->{$k}->{EhrInspectionID},5,$res); 
};
             

