#! /usr/bin/perl

use warnings;
use strict;

my $scriptName = "hwswBaselines.pl";
my $scriptVersion="2.5.0";

# This script gathers up hardware and software info and writes out to separate
# files.
# 
# Most of the info gathered is specific to macOS.
#
#

#### Some version history:
## 2.0.2 Added sysctl.
## 2.0.2 Changed sub outputToFile.  Now writing data directly to file handle vs collecting in variable.
## 2.0.2 Added an output file to include this script itself.
## 2.0.3 Added: ioreg -l
## 2.0.3 Added: /usr/libexec/remotectl get-property localbridge HWModel
## 2.1.0 Changed [remotectl get-property localbridge HWModel] to simply [remotectl dumpstate]
## 2.2.0 Use mkdir to create output directory instead of backticks.  Still using backticks to mkdir on parent directories.
## 2.2.0 Chdir to ENV{'HOME'} before `mkdir` to avoid potential special characters in path name.
## 2.3.0 Added variable $sleepBetween so as to easily skip sleeping.
## 2.3.0 Modified outputToFile.  Redirecting STDERR of each command to a file in errors subdirectory.
## 2.4.0 Changed output directory structure
## 2.5.0 Changes to $outDir
## 2.5.0 Added ioreg -a
## 2.5.0 Added command line processing in parseArgs
## 2.5.0 Added -h command line option


######################################################################
#### Begin Global variables.
my $runDate = timestamp_log(time);
my $outDir; # = "baselines" # "baselines-macOS/$scriptVersion/$runDate";
my $hwm = "/Applications/Utilities/HardwareMonitor.app/Contents/MacOS/hwmonitor";
my $runReason = "NoneGiven";
my $outFile;
my $backtickString;
my $sleepBetween = 1;  
my $thisOS = "";
my $usage = "\nUsage: ./$scriptName [-h -n -s]\n\n\t[-n] Notes. Specify text to be written to runReasonNotes file.\n\n\t[-h] Help. Display help and usage info.\n\n\t[-s] Toggle delay (sleep) inbetween operations.\n\nEXAMPLES\n\n\t ./$scriptName -n \"clean install of OS\"\n\n";
my $notes = "None given.";
#### End Global variables.
######################################################################




parseArgs() if @ARGV;  ## Change variables according to run time arguments. 




print "\nRunning $scriptName $scriptVersion at $runDate\n";




#### Set OS flag

if ($^O =~ /darwin/i) {
	$thisOS = "mac";
}

if ($^O =~ /MSwin32/i) {
	$thisOS = "win";
}




#### Build output directory structure.

if ( $ENV{SYSTEMDRIVE} && $ENV{HOMEPATH} ) {
	$outDir = "$ENV{SYSTEMDRIVE}$ENV{HOMEPATH}"; 
}

if ( $ENV{'HOME'} ) {
	$outDir = "$ENV{'HOME'}"; 
}

unless ( -d $outDir ) { print "outDir does not exist. [$outDir]  Connot continute.\n"; exit;}
unless ( -w $outDir ) { print "outDir is not writeable. [$outDir]  Connot continute.\n"; exit;}


my @outDirs;
push @outDirs, $outDir; 
push @outDirs, $outDirs[$#outDirs] . "/baselines"; 
push @outDirs, $outDirs[$#outDirs] . "/$scriptName";
push @outDirs, $outDirs[$#outDirs] . "/$scriptVersion";
push @outDirs, $outDirs[$#outDirs] . "/$runDate";
push @outDirs, $outDirs[$#outDirs] . "/errors";
 
for my $path (@outDirs) {

	unless ( -d $path ) {
		print "Creating directory at $path\n"; 
		mkdir $path or die "Could not mkdir $path $!";
	
	}

}


$outDir = $outDirs[4];

print "Will save results in $outDir\n";




#### Open LOGFILE to write status to.
open (LOGFILE, ">>","$outDir/runLog.txt") or die "Could not open file for writing $!";
print LOGFILE "Started $scriptName $scriptVersion at $runDate\n";




#### Sleep for 5 minutes to let things stabilize.
if ($sleepBetween) {
	print "Sleeping for 5 minutes to let things stabilize.\nStarted sleeping at: " . timestamp_log(time) . "\n";
	print LOGFILE "Sleeping for 5 minutes to let things stabilize.\nStarted sleeping at: " . timestamp_log(time) . "\n";
	print LOGFILE "\n";
	sleep 300;
}




#### Output hw and sw info to separate text files.

## output top
$outFile = "01_top_-l_1__$runDate.txt";
$backtickString = "top -l 1";
outputToFile($outFile,$backtickString);


## output ps axu
$outFile = "02_ps_axu__$runDate.txt";
$backtickString = "ps axu";
outputToFile($outFile,$backtickString);


## output uptime
$outFile = "03_uptime__$runDate.txt";
$backtickString = "uptime";
outputToFile($outFile,$backtickString);


## output kextstat
$outFile = "04_kextstat__$runDate.txt";
$backtickString = "kextstat";
outputToFile($outFile,$backtickString);


## Output temperatures. Requires Hardware Monitor from Marcel Bresink @ http://www.bresink.com/ installed in default location.
if (-x $hwm) {

	if ($sleepBetween) {
		print "Sleeping 2 minutes to let temperatures stabilize.\nStarted sleeping at: " . timestamp_log(time) . "\n";
		print LOGFILE "Sleeping 2 minutes to let temperatures stabilize.\nStarted sleeping at: " . timestamp_log(time) . "\n";
		sleep 120;
	}

	$outFile = "05_hwmonitor__$runDate.txt";
	$backtickString = "$hwm";
	outputToFile($outFile,$backtickString);

} else {

	$outFile = "05_NULLhwmonitor__$runDate.txt";
	$backtickString = "echo 'Could not find or execute $hwm'";
	outputToFile($outFile,$backtickString);
	print "No monitor found executable at [$hwm]\n";

}

	
## Output USER lsof -n
$outFile = "06_lsof_-n__USER__$runDate.txt";
$backtickString = "lsof -n";
outputToFile($outFile,$backtickString);


## Output USER lsof
$outFile = "07_lsof__USER__$runDate.txt";
$backtickString = "lsof";
outputToFile($outFile,$backtickString);


## Output vmstat
$outFile = "08_vm_stat__$runDate.txt";
$backtickString = "vm_stat";
outputToFile($outFile,$backtickString);


## Output system_profiler TEXT only
$outFile = "09_system_profiler_-detailLevel_full__$runDate.txt";
$backtickString = "system_profiler -detailLevel full";
outputToFile($outFile,$backtickString);


## Output system_profiler XML version
$outFile = "10_system_profiler_-detailLevel_full_-xml__$runDate.spx";
$backtickString = "system_profiler -detailLevel full -xml";
outputToFile($outFile,$backtickString);


## Output nvram -p
$outFile = "11_nvram_-x_-p__$runDate.xml";
$backtickString = "nvram -x -p";
outputToFile($outFile,$backtickString);


## Output sysctl -a
$outFile = "12_sysctl_-a__$runDate.txt";
$backtickString = "sysctl -a";
outputToFile($outFile,$backtickString);


## Output ioreg -l
$outFile = "13_ioreg_-l__$runDate.txt";
$backtickString = "ioreg -l";
outputToFile($outFile,$backtickString);


## Output ioreg -a
$outFile = "14_ioreg_-a__$runDate.txt";
$backtickString = "ioreg -a";
outputToFile($outFile,$backtickString);


## Output /usr/libexec/remotectl dumpstate (not sure what good this is)
$outFile = "15_remotectl_dumpstate__$runDate.txt";
$backtickString = "/usr/libexec/remotectl dumpstate";
outputToFile($outFile,$backtickString);


## Output runReason (After other baselines have completed.)
# processArgs() if ($ARGV[0]) ;
$outFile = "00_runReasonNotes__$runDate.txt";
$backtickString = "echo $notes";
outputToFile($outFile,$backtickString);



print "\nAll output complete.\n";

print "\nShould also get an lsof as admin using:
sudo lsof > $outDir/06_lsof_-n__ROOT__$runDate.txt
and 
sudo lsof > $outDir/06_lsof__ROOT__$runDate.txt"; 

print "\nShould also get logs as admin using:
sudo log collect --last 1d --output=outDir\n\n";

print "Be sure to update $outFile if needed.\n";

print         "All output complete.\n\n";
print LOGFILE "All output complete.\n\n";
print         "Results saved in [$outDir]\n\n";
print LOGFILE "Results saved in [$outDir]\n\n";
print         "$scriptName $scriptVersion done.\n";
print LOGFILE "$scriptName $scriptVersion done.\n";



if ($thisOS eq "mac") { system("open $outDir"); } 
if ($thisOS eq "win") { system("start $outDir"); } 

close LOGFILE or die "Could not close LOGFILE filehandle on $outDir/runLog.txt. $!";




exit;




##############################################################################
##############################################################################


sub outputToFile {

	unless ($_[0] && $_[1]) { die "Bad input to outputToFile subroutine. $!"; }


	my $outputFileName = $_[0]; 
	my $commandToBacktick = $_[1];
	
	
	my $outputFile = "$outDir/$outputFileName";
	
	print         "Writing output of [$commandToBacktick] to [$outputFileName]\n";
	print LOGFILE "Writing output of [$commandToBacktick] to [$outputFileName]\n";

	die "Will not overwrite [$outputFile]\n" if (-e $outputFile);

	open (OUTFILE, ">", "$outputFile") or die "Could not open file for writing.  \$outputFile was: [$outputFile]. $!";
 
	print LOGFILE "Command was: $commandToBacktick\n" or die "Could not write \$commandToBacktick [$commandToBacktick] to LOGFIlE $outDir/runLog.txt $!";

	print OUTFILE `$commandToBacktick 2>$outDir/errors/$outputFileName.stderr` or die "Could not print to filehandle.  File was [$outputFile]. Backtick command was $commandToBacktick. $!";

	if ($?) { warn "WARNING: Command failed.  Command was [$commandToBacktick]\n \$? was [$?] $!"; }
	
	sleep 3 if $sleepBetween;

    close OUTFILE or die "Could not close filehandle on \$outputFile [$outputFile] $!";

	if ($sleepBetween) {
		print         "Sleeping for 30 seconds\n\n";
		print LOGFILE "Sleeping for 30 seconds\n\n";
		sleep 30;
	}
}




sub parseArgs {
	
	return 0 unless @ARGV;
	
	## Define legal arguments.
	my %legalArgs;
	$legalArgs{'-h'} = 1; ## help
	$legalArgs{'-H'} = 1; ## Help
#	$legalArgs{'-p'} = 1; ## Number of passes to perform.
	$legalArgs{'-n'} = 1; ## Notes added to the notes column in CSV output.
#	$legalArgs{'-a'} = 1; ## Anonymous flag. 
	$legalArgs{'-s'} = 1; ## Pause before starting first operation and in between all other operations.

	for my $i (0 .. $#ARGV) { 
		
		## User asked for help so print usage and exit.
		if ($ARGV[$i] eq "-h" || $ARGV[$i] eq "-H") { print $usage; exit;} 

		## Look for illegal argument.
		if ($ARGV[$i] =~ /^-/) {
			unless ($legalArgs{$ARGV[$i]}) {
				print "\nILLEGAL OPTION: $ARGV[$i]\n\n";
				print $usage;
				exit;
			}
		}	
		
		## First argument needs to start with a dash.
		unless ($ARGV[0] =~ /^-/) {
			print "\nILLEGAL OPTION: $ARGV[0]\n\n";
			print $usage;
			exit;
		}	

		
		
		## Extract -s flag which toggles $sleepBetween variable.
		## Eefault is 1.
		if ($ARGV[$i] eq "-s") {

			if ($sleepBetween == 1) { $sleepBetween = 0; last; }
		
			if ($sleepBetween == 0) { $sleepBetween = 1; last; }
			

		}

		## Extract notes from -n argument
		if ($ARGV[$i] eq "-n" &&  defined $ARGV[$i+1] ) {
			$notes = $ARGV[$i+1];
			
		 	## Escape quotes ( " ' ` ) so echo does not have issues.
			$notes =~ s/"/\\"/g;  
			$notes =~ s/'/\\'/g;
			$notes =~ s/`/\\`/g;
			
			
		}

		
	}
	
	
	return;	
}




sub timestamp_log {
	## return a time value in the form yyyymmdd-hhmmss

	my $timeValue = $_[0];
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($timeValue);
	
	$year += 1900;
	my $month = $mon+1;
	$month = sprintf("%02d",$month);
	my $day = sprintf("%02d",$mday);
	$hour = sprintf("%02d",$hour);
	$min = sprintf("%02d",$min);
	$sec = sprintf("%02d",$sec);
	return "$year$month$day-$hour$min$sec";

}