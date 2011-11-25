#!/usr/bin/perl

# First written by orczhou.com orchzou@gmail.com
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2 of the License.

#  The backup file of mysqldump is sometimes very huge, if you wanna restore one 
#  or two table from the file, there is no easy way to do this. There some way we 
#  try:
#    1. split/csplit the file
#    2. restore some tables.
#  This script will get a tiny improvement, all you need do is :
#    tbdba-restore-mysqldump.pl -t process,user -s monitor -f backup.sql
#
#  Feature:
#    When all the table has been found and -s is specified, exit immediately.
#    So it's quicker;
#  
#  To do:
#   1. add a parameter to output the sql files of all tables.
#      tbdba-restore-mysqldump.pl --all-tables -f backup.sql
#  

use strict;
use File::stat;     # To get the file stat
use Time::localtime;
use Socket;
use Getopt::Long;

sub print_usage () {
  my $text = <<EOF;
 NAME:
    tbdba-restore-mysqldump.pl

 SYNTAX:
    Sample:
       1. Get table "process" from backup.sql
          tbdba-restore-mysqldump.pl -t process -f backup.sql
       2. Get table "process" of database "monitor" from backup.sql
          tbdba-restore-mysqldump.pl -t process -s monitor -f backup.sql
       3. Get table "process","users" of database "monitor" from backup.sql
          tbdba-restore-mysqldump.pl -t process,user -s monitor -f backup.sql
       4. Get the table sql file from a STDIN 
          gunzip -c backup.sql.gz|tbdba-restore-mysqldump.pl -t process,user -s monitor

 FUNCTION:
    Restore some tables from the while mysqldump backup

 PARAMETER:
    -t|--table=s
        which table you wanna recovery
    -s|schema=s
        in which schema the table your wanna recovery
    -f|sql-file=s
        from which mysqldump backup file 
    -d|--debug
        debug mode; more output will be there
    -h|--help
        you already know
EOF
 print STDERR $text;
 exit 0;
}

my %opt = (
);

GetOptions(\%opt,
    's|database=s',           # write result to database
    'f|sql-file=s',           # write result to database
    't|table=s',                  # debug mode  
    'd|debug+',                  # debug mode  
    'h|help+',                  # debug mode  
    # order-by: 
    #   execs|Query_time:cnt
    #   ela_time|Query_time:sum 
) or print_usage();

print_usage() if $opt{h};
my $file = "";
my $db = "";
my @tabs ;
my $inTableFlag = 0;
my $inDBFlag = 0;
my $outputdir = "./";
push(@tabs, $opt{t}) if $opt{t};
@tabs = split(/,/,join(',',@tabs));
my $tabcount = scalar(@tabs);
$db = $opt{s} if $opt{s};
$file = $opt{f} if $opt{f};

# if no db speicefied, all db is allowed
if($db eq ""){
  $inDBFlag = 1;
}

my $curtab = "";
my $curdb = "";
open (TABFILE, ">>STDERR"); 
my $ifh;
if($file eq ""){
  $ifh = *STDIN;
}else{
  open $ifh,"<", $file or die $!;
}
while(<$ifh>){
  if ($_ =~ /^-- Current Database\: `(.*)`/){
    $curdb = $1;
    print "$_ \n" if $opt{d};
    if($db ne ""){
      if($inDBFlag == 1){
        # if $db ne "" and $inDBFlag == 1, A new database coming, now we quit
        exit 0;
      }
      $inDBFlag = 0;
      $inDBFlag=1  if $1 eq $db;
    }
  }elsif ($_ =~ /^-- Table structure for table `(.*)`/){
    if($db ne ""  && $tacount == 0){exit 0;}
    $curtab = $1;
    $inTableFlag = 0;
    close (TABFILE);
    for(my $i=0;$i <= scalar(@tabs);$i++){
      if($tabs[$i] eq $1) {
        $inTableFlag=1;
        if($inTableFlag == 1 && $inDBFlag == 1){
          $tabcount = $tabcount - 1;
          open (TABFILE, ">>$outputdir"."$curdb."."$curtab"); 
        }
      };
    }
  }else{
    if($inTableFlag == 1 && $inDBFlag == 1) {print TABFILE $_;}
  }
}
