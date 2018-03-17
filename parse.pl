#!/usr/bin/perl
use strict;
use utf8;
use XML::Parser;
use Data::Dumper;
use Encode qw/ decode /;
use DBI;

my $dsn = "DBI:mysql:database=patients;host=localhost";
my $dbh = DBI->connect($dsn, "debian-sys-maint", "abUYOCiQVq7CMTmp");

open(FDDIAG,">diagnosis.train.txt");
open(FDTREAT,">treatments.train.txt");
open(FDCOMPL,">complaints.train.txt");

use RTF::TEXT::Converter;

binmode(STDOUT,':utf8');
binmode(FDDIAG,':utf8');
binmode(FDTREAT,':utf8');
binmode(FDCOMPL,':utf8');

open(my $fh, "<", "data.xml");

our %AllPatAttrs = (
 'Id' => '\d+',
 'Gender' => '.',
 'BirthDate' => '\d{4}-\d{2}-\d{2}'
);

our %Visit = ();

our %VisitAttrs=(
 'Goal' => '.*',
 'CompletionAttribute' => '.*',
 'RepeatedAttribute' => '.*',
 'DiagnosResult' => '.*',
 'CaseResult' => '.*',
 'HelpType' => '.*',
 'BeginDate' => '\d{4}-\d{2}-\d{2}',
 'EndDate' => '\d{4}-\d{2}-\d{2}'
);

our %EhrInspection = ();

our %EhrInspectionAttrs=(
 'Date' => '\d{4}-\d{2}-\d{2}',
 'Place' => '.*',
 'ComplaintsRTF' => '.*',
 'AnamnesisRTF' => '.*',
 'ObjectiveFindingsRTF' => '.*',
 'TreatmentRTF' => '.*',
 'DiagnosRTF' => '.*'
);

our %maxlength = ();

our %Diagnos = ();
our $VisitID=0;
our %DiagnosAttrs=(
 'Code' => '\s+',
 'DiseaseType' => '.*',
 'DiagnosType' => '.*',
 'TraumaType' => '.*',
 'TraumaReasonCode' => '.*' );

our %PatientAttrs=();

our %CurrentText=();



our $CurrentTag=undef;

my $string;
my $conv = RTF::TEXT::Converter->new(
               output => \$string
           );
 

my $parser = new XML::Parser ( Handlers => {   # Creates our parse object
                              Start   => \&hdl_start,
                              End     => \&hdl_end,
                              Char    => \&hdl_char,
                              Default => \&hdl_def,
                            });
$parser->parse($fh);
   
  # The Handlers

sub hdl_start{
      my ($p, $elt, %atts) = @_;
      $CurrentText{$elt}='';
      $CurrentTag = $elt;
};      
 
 

sub hdl_end{
      my ($p, $elt) = @_;
      if(defined($AllPatAttrs{$elt})) {
         $PatientAttrs{$elt}=$CurrentText{$elt};
      } elsif(defined($VisitAttrs{$elt})) {
         $Visit{$elt} = $CurrentText{$elt};
      } elsif(defined($EhrInspectionAttrs{$elt})) {
         if($elt =~/RTF$/) {
             $string="";
             $conv->parse_string($CurrentText{$elt});

             $EhrInspection{$elt} = decode('Windows-1251', $string);

             my $l = length($EhrInspection{$elt});
             if(not(defined($maxlength{$elt})) or ($l > $maxlength{$elt} ) ) {
                 $maxlength{$elt} = $l;
             };
         } else {
             $EhrInspection{$elt} = $CurrentText{$elt};
         };
      } elsif(defined($DiagnosAttrs{$elt})) {
         $Diagnos{$elt} = $CurrentText{$elt};
      } elsif($elt eq 'EhrVisit') {
         print 'INSERT INTO Visit SET VisitID='.$VisitID.', PatientID='.$PatientAttrs{Id}.',';
         print join(',', 
             map { "$_=".$dbh->quote($Visit{$_})."" } 
                 keys(%Visit)).";\n";

         $VisitID ++;
         %Visit = ();
      } elsif($elt eq 'EhrVisitList') {
      } elsif($elt eq 'EhrInspectionList'){
      } elsif($elt eq 'Diagnos') {
         print 'INSERT INTO Diagnos SET VisitID='.$VisitID.',';
         print join(',',
             map { "$_=".$dbh->quote($Diagnos{$_}) }
                 keys(%Diagnos) ).";\n";
         %Diagnos = ();
      } elsif($elt eq 'DiagnosList') {
      } elsif($elt eq 'EhrInspection') {
         if(length($EhrInspection{DiagnosRTF}) <=2) {
            if($EhrInspection{ComplaintsRTF} =~s/[Дд]иагноз\s*:?\s*([^\.]+)\.//) {
                $EhrInspection{DiagnosRTF} = $1;
            };
            if($EhrInspection{ComplaintsRTF} =~s/[Дд]-[Зз]\s*:\s*([^\.]+)\.//) {
                $EhrInspection{DiagnosRTF} = $1;
            };
         };
         if(length($EhrInspection{TreatmentRTF}) <= 2) {
            if($EhrInspection{ComplaintsRTF} =~s/[Рр]екомендации\s*:\s*([^\.]+)\.//) {
                $EhrInspection{TreatmentRTF} = $1;
            };
         };
         print 'INSERT INTO EhrInspection SET VisitID='.$VisitID.',';
         print join(',',
             map { "$_=".$dbh->quote($EhrInspection{$_}) }
                 keys(%EhrInspection) ).";\n";
         $EhrInspection{TreatmentRTF} =~ s/\n/ /g;
         $EhrInspection{DiagnosRTF} =~ s/\n/ /g;
         $EhrInspection{ComplaintsRTF} =~ s/\n/ /g;
         
         print FDDIAG lc($EhrInspection{DiagnosRTF})."\n";
         print FDTREAT lc($EhrInspection{TreatmentRTF})."\n";
         print FDCOMPL lc($EhrInspection{ComplaintsRTF}." ".$EhrInspection{ObjectiveFindingsRTF})."\n";

         %EhrInspection = ();
      } elsif($elt eq 'Patient') {
         print 'INSERT INTO Patient SET ';
         print join(',', map { "$_=".$dbh->quote($PatientAttrs{$_}) } keys(%PatientAttrs)).";\n";
         %PatientAttrs=();
       
      } else {
         print "Unknown elt: '".$elt."'\n";
         print "Known are: ".Dumper(\%AllPatAttrs);
      };
}
  
sub hdl_char {
    my ($p, $str) = @_;
    $CurrentText{$CurrentTag}.=$str;
};

sub hdl_def { }  # We just throw everything else

print STDERR Dumper(\%maxlength);
