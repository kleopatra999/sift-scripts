#! /usr/bin/perl
#---------------------------------------------------------------
# macl.pl - CLI MACLookup script; script to take a WAP MAC address, or a file
# containing MAC addresses, and look up their lat/longs (if available) via
# Wigle.net (NOTE: You MUST have a Wigle.net username/password - registration
# is free.).  Output formats are tabular (default), CSV, or KML (for opening 
# in Google Earth).  The "web" format (the "-w" switch) will print out (to
# STDOUT) a Google Maps URL that you can paste into your browser location 
# bar.  This is useful if you just want to see each point individually, or if
# you have only one point, or if you don't have Google Earth installed or
# available.
#
#
# Change History
#   20111112 - created
#
# References
#  http://cpan.uwinnipeg.ca/htdocs/Net-Wigle/Net/Wigle.pm.html
#  KML format: http://code.google.com/apis/kml/documentation/kml_tut.html
#  IGiGLE: http://www.irongeek.com/i.php?page=security/igigle-wigle-wifi-to-
#                 google-earth-client-for-wardrive-mapping
#
# This program is free software, and is released as-is, with no warranties.
# You can redistribute and/or modify it under the terms of the GNU General
# Public License, version 3 or later (see http://www.gnu.org/licenses).
#
# copyright 2011 Quantum Analytics Research, LLC
#---------------------------------------------------------------
use strict;
use Net::Wigle;
use Getopt::Long;

my $VERSION = "1\.0";
my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config,qw(file|f=s mac|m=s kml|k csv|c web|w user|u=s pass|p=s help|?|h));

my %mac_addr;

if (!%config || !$config{pass} || $config{help}) {
	_syntax();
	exit 1;
}

if ($config{mac}) {
	$mac_addr{$config{mac}} = 1;
}

if ($config{file}) {
	if (-e $config{file} && -f $config{file}) {
		open(FH,"<",$config{file});
		while(<FH>) {
			next if ($_ =~ m/^#/ || $_ =~ m/^\s+$/);
			chomp;
			$_ =~ s/\s/:/g;
			$_ =~ s/\-/:/g;
			my @items = split(/:/,$_);
			if (scalar @items == 6) {
				$mac_addr{$_} = 1;
			}
			else {
# too few elements; not a MAC address				
			}			
		}
		close(FH);
	}
	else {
		print $config{file}." not found.\n";
	}
}

#-------------------------------------------------------------
# 
#-------------------------------------------------------------
my %wap;
foreach my $m (keys %mac_addr) {
	
	my $r = lookup($m);
	if ($r->[0]->{trilong} != "" && $r->[0]->{trilat} != "") {
		$wap{$r->[0]->{netid}}{lat}  = $r->[0]->{trilat};
		$wap{$r->[0]->{netid}}{long} = $r->[0]->{trilong};
		$wap{$r->[0]->{netid}}{ssid} = $r->[0]->{ssid};
		$wap{$r->[0]->{netid}}{wep}  = $r->[0]->{wep};
	}
	else {
#		print "Lat/Longs not found.\n";
	}
}

#-------------------------------------------------------------
# Print out returned info to STDOUT, based on format choices
#-------------------------------------------------------------
if ($config{csv}) {
	print "MAC Addr,Lat,Long,SSID,WEP\n";
	foreach my $k (keys %wap) {
		print $k.",".$wap{$k}{lat}.",".$wap{$k}{long}.",".$wap{$k}{ssid}.",".$wap{$k}{wep}."\n";
	}
}
elsif ($config{web}) {
	foreach my $k (keys %wap) {
		my $url = "http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=".
		          $wap{$k}{lat}."+".$wap{$k}{long}."+(".$wap{$k}{ssid}.")&iwloc=A&hl=en";
		print $url."\n";
		print "\n";
	}
}
elsif ($config{kml}) {
	print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print " <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n";
  
  foreach my $k (keys %wap) {
  	print "  <Placemark>\n";
  	print "    <name>".$wap{$k}{ssid}."</name>\n";
  	print "    <description>".$k." - WEP = ".$wap{$k}{wep}."</description>\n";
  	print "    <Point>\n";
  	print "      <coordinates>".$wap{$k}{long}.",".$wap{$k}{lat}.",0</coordinates>\n";
  	print "  </Point>\n";
  	print "  </Placemark>\n";	
  }
  print "</kml>\n";
}
else {
	foreach my $k (keys %wap) {
		print $k."\n";
		print "  Lat : ".$wap{$k}{lat}."\n";
		print "  Long: ".$wap{$k}{long}."\n";
		print "  SSID: ".$wap{$k}{ssid}."\n";
		print "  WEP : ".$wap{$k}{wep}."\n";
		print "\n";
	}
}

#-------------------------------------------------------------
# 
#-------------------------------------------------------------
sub lookup {
	my $addr = shift;
	
	my $wigle = Net::Wigle->new; 
	my $result = $wigle->query(
  	user => $config{user},
  	pass => $config{pass},
  	netid => $addr,
	);
	return $result;
}

#-------------------------------------------------------------
# 
#-------------------------------------------------------------
sub _syntax {
	print<< "EOT";
MACLookup v.$VERSION - CLI MACLookup tool	
macl [-f text file] [-m mac_addr] [-u username] [-p password] [-c][-k][-w][-h]
Use Wigle\.net to attempt to lookup lat/long for WiFi MAC address(es)\.
You must have a Wigle\.net username & password.

  -f file............parse flat text file containing MAC addresses
  -m mac_addr........look up this MAC address
  -c ................output list in CSV format
  -k ................output in KML format (open in Google Earth) 
  -w ................output each point as a Google Maps URL
  -u username........Wigle\.net username
  -p password........Wigle\.net password
  -h.................Help (print this information)
  
Ex: C:\\>macl\.pl -u user -p pass -f macs\.txt
    C:\\>macl\.pl -u user -p pass -m 00:11:22:33:44:55:66 -c
    
All output goes to STDOUT; use redirection (ie, > or >>) to output to a file\.
  
copyright 2011 Quantum Analytics Research, LLC
EOT
}
