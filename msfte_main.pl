#!/usr/bin/perl -w
## (C) Copyright 2006 IBM Corporation
##=========================================================================
## Script Name    : msfte_main.pl
## Script Purpose : extract iam data
## Output         : result.txt and err.txt under the current directory
## Dependencies   : Perl
##-----------------------------------------------------------------------
## Version     Date         # Author              Description
##   0.1     2014-12-24      Jimmy Zhang          zhang.arthur@gmail.com
##   0.2     2014-12-31      Jimmy Zhang          zhang.arthur@gmail.com
##   0.3     2015-07-31      Jimmy Zhang          zhang.arthur@gmail.com
use strict;
use threads;
use Net::OpenSSH;
use Term::ANSIColor;
use File::Basename qw(fileparse);
use Getopt::Std;
use vars qw($opt_l $opt_L $opt_o $opt_O $opt_U $opt_u $opt_P $opt_p $opt_T $opt_t
           $opt_s $opt_S $opt_r $opt_R $opt_h $opt_H $opt_b $opt_B $opt_g $opt_G);
my $script    = "msfte_main.pl";
my $script_version = "0.3";
our ($user,$key,$time_out,$max_thread);
require ('init_param.pl');
my ($host_file,$cmd);
my $intrs=0;
my $dir='ms_upload';
my @b;
my %param = (
        user => $user,
        key_path => $key,
        timeout => $time_out,
        async => 1,
        master_stderr_discard => 1,
     );
sub Init_id{
 print "The file:init_param.pl had been created\n";
 if (-e $dir) {
     print "Your directory:ms_upload exists\n";
    }
 else {
    print "The directory ms_upload will be created for scp\n";
    mkdir($dir)
    };
 if ($intrs eq 1) {
 open (FH, "<","init_param.pl") or die "we can't open $!\n";
 open (OUT, ">","init_param.pl.tmp") or die "we can't create $!\n";
    while (<FH>) {
        next if $_=~/time_out/;
        print OUT;
       }
        print OUT "\$time_out=$time_out;\n";
        close OUT;
        close FH;
        unlink("init_param.pl");
        rename("init_param.pl.tmp","init_param.pl");
     }
 else {
 open (FH, ">","init_param.pl") or die "we can't open $!\n";
     print FH "\$max_thread=20;\n";
     print FH "\$time_out=05;\n";
     print FH "\$user=\"$user\";\n";
     print FH "\$key=\"$key\";\n";
     close FH;
    }
}
sub Batch_cmd {
         my $host=shift;
         chomp($host);
         my $ssh = Net::OpenSSH->new($host,%param);
         $ssh->error and die "Can't ssh to $host: " . $ssh->error;
         if ($intrs eq 1){
            $ssh->scp_put({recursive => 1},"$cmd", '/tmp/')
            or die "scp failed:$host " . $ssh->error;
            my ($fname,$fdir)=fileparse($cmd);
            $cmd="sudo /tmp/$fname;rm /tmp/$fname";}
         #my ($stdout,$stderr)=$ssh->capture2({tty=>1,stdin_discard =>1},$cmd);
         my ($stdout,$stderr)=$ssh->capture2($cmd);
         if($stdout){
             print RES "---$host---\n";
             #print  "---$host---\n";
             print RES $stdout; }
             #print  $stdout; }
         else {
              print ERR "---$host---\n";
              #print "---$host---\n";
              #print $stderr and print ERR $stderr;
              $stderr and print ERR $stderr;
              #print  $stderr;
             }
}
sub Scp_cmd {
         my $host=shift;
         chomp($host);
         my $ssh = Net::OpenSSH->new($host,%param);
         $ssh->error and die "Can't ssh to $host: " . $ssh->error;
         if ($intrs eq 1 ) {
              $ssh->scp_get({recursive => 1,glob => 1}, "$cmd", './')
               or die "scp failed:$host " . $ssh->error;
             print RES "The file/dir from $host had been obtained to the current dir successfully !\n";
         }
         else {
             $ssh->scp_put({recursive => 1,glob => 1},"$cmd", '/tmp')
             or die "scp failed:$host " . $ssh->error;
             print RES "The file/dir had been tranferred to $host:/tmp successfully!\n";
        }
}
sub Main_cmd {
my @a;
my $b=$_[0];
#require ('init_param.pl');
#do 'init_param.pl';
open (HOSTS,"<","$host_file") or die "Your server list can't be found\t$!\n";
open (RES,">>","result.txt") or die "Your result.txt can't be appened\t$!\n";
open (ERR,">>","err.txt") or die "Your err.txt can't be appened\t$!\n";
for (my $i=0;$i<=$max_thread;$i++) {
while( <HOSTS> ) {
         chomp;
        push @a, threads -> new($b,$_);
   }
 }
$_->join for @a;
close HOSTS;
close RES;
close ERR;
}

sub Usage {
    print color 'bold yellow';
    print << "USAGE";
------------------------------------------------------------------------------------------------------------
$script v$script_version
------------------------------------------------------------------------------------------------------------
1.$script -u <username> -p </home/username/.ssh/id_rsa ##initial user/ssh key
2.$script -t <60>          specify 60s timeout of ssh connection  ##SSH repeat try
3.$script -l <server_list> ";" between multi commands:<uptime;ls>  ##Batch commands
4.$script -l <server_list> -b  </tmp/test01.sh> ##execute the script ##Run the script
5.$script -l <server_list> -s  <Put the file/dir to remote server:/tmp> ##Put
6.$script -l <server_list> -g  <Get the file/dir from remote server to the currect dir>
7.$script -l <server_list> -b getNodeRpmList.pl Generate the applicable APARs report according to secfixdb
8.$script -l <server_list> -b yumNodeinstall.pl APARs batch installation according to APARs report
------------------------------------------------------------------------------------------------------------
You must execute Step.1 to set initial id for OPENSSH
-------------------------------------------------------------------------------------------------------------
USAGE
   print color 'reset';
}


if( @ARGV < 2 )
{
 &Usage;
}
getopts("l:L:o:O:u:U:p:P:s:S:b:B:g:G:t:T:");
if ($opt_t){
    $time_out=$opt_t;
    $intrs=1;
    &Init_id;
}
if ($opt_u and $opt_p){
    $user=$opt_u;
    $key=$opt_p;
    &Init_id;
}
if ($opt_l){
  if (defined($opt_b)) {
    $host_file=$opt_l;
    $cmd=$opt_b;
    $intrs=1;
    if ( -e $cmd ) {
     &Main_cmd(\&Batch_cmd);
        }
    else { print "Your file/dir couldn't be found!\n"
        }
   }
  elsif (defined($opt_s)) {
    $host_file=$opt_l;
    $cmd=$opt_s;
    if ( -e $cmd ) {
    &Main_cmd(\&Scp_cmd);
        }
    else { print "Your file/dir couldn't be found!\n"
        }
    }
  elsif (defined($opt_g)) {
    $host_file=$opt_l;
    $cmd=$opt_g;
    $intrs=1;
    &Main_cmd(\&Scp_cmd);
   }
  else {
   $host_file=$opt_l;
   print "Please input your batch command\n";
   $cmd = <STDIN>;
   &Main_cmd(\&Batch_cmd);
   }
}

