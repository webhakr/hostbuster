#!/usr/bin/perl
###########################################################################
# Perl script to test for vhosts on a given IP

# Usage - hostbuster.pl --ip <IP address to test> 
#                       --domain <root domain>
#                       --subs <file containing subdomains>
#                       --proxy <http://proxyIPorURL:port>]

# roydavis@roydavis.org - Roy Davis 05/15/2015 - v1.0

# Copyright (C) 2015  Roy Davis

# Props Geoff Jones (geoff.jones@cyberis.co.uk) for his work on
# "vhostchecker.pl (04/02/2013 - v0.1 Copyright (C) 2013  Cyberis Limited)
# on which this script is based. I have modified it quite a bit, and 
# changed the functionality such that this tool will ID website subdomains
# that are not in DNS at all. This typically happens when a sysadmin is
# trying to hide a site using a vhost and no corresponding CNAME DNS rec.
# The "subDomains.txt" file has ~36K entries. The majority of this file also
# originated with Geoff Jones and the "vhostchecker.pl" project, but I added
# a bunch more. Please feel free to add your own. The more the better!!

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###########################################################################

use warnings;
use strict;
use Getopt::Long;
use Term::ANSIColor;

require LWP::UserAgent;
require LWP::Protocol::https;

my @subs;

my $targetIp;
my $subsListFile;
my $nocolor = '';
my $useragent = 'Mozilla/5.0';
my $proxy;
my $domain = '';
my $ua;
my $domainContentLength;
my $curDomain;

GetOptions("targetIp=s"     => \$targetIp,
	   "domain=s"       => \$domain,
	   "subsListFile=s" => \$subsListFile,   
	   "proxy=s"        => \$proxy); 

if (! defined($targetIp) || ! defined($subsListFile)) 
{
	print usage();
	exit;
}

loadSubsListFile();

print STDERR "[INFO] Read ". @subs ." subdomains from file \"$subsListFile\" \n";

setDomainContentLength();

print STDERR "[INFO] $domain content length = $domainContentLength \n";

processSubsListFile();

exit;










###########################################################################
sub processSubsListFile
###########################################################################
{
	foreach (@subs) 
	{
		$curDomain = $_;
	
		#print "\nChecking Domain: $curDomain ";
	
		# User Agent Object;
		$ua = LWP::UserAgent->new(agent => $useragent);
	
		if ( defined($proxy))
		{
			$ua->proxy(['http', 'ftp'], $proxy);
		} 
	
		$ua->default_header('Host' => $curDomain); 
	
		my $response = $ua->get("http://$targetIp/");
	
		printResponse($response);
	}
}

###########################################################################
sub usage 
###########################################################################
{
	print STDERR "\nPerl script to test for vhosts on a given IP\n\n";
	print STDERR "\tUsage - $0 --ip <IP addr. to test> --domain <root domain>\n";
	print STDERR "\t\t--subs <file containing subdomains> [--nocolor] [-u 'useragent']\n\n";
	print STDERR "\t\t[--proxy <http://proxyIPorURL:port>]\n\n";
}


###########################################################################
sub loadSubsListFile
###########################################################################
{
	# Load the subsListFile into memory. append the domain to the end of each
	open(F,$subsListFile) or die "Failed to open file containing list of subDomains to check - $!\n";
	
	while (<F>)
	{
		chomp;
		next if (m/^ *$/);
	        push (@subs, $_ . "." . $domain);
	}
	
	close(F);
}

###########################################################################
sub setDomainContentLength
###########################################################################
{
	my $ua = LWP::UserAgent->new(agent => $useragent);
	
	if ( defined($proxy))
	{
		$ua->proxy(['http', 'ftp'], $proxy);
	} 
	
	$ua->default_header('Host' => $domain); 
	
	my $response = $ua->get("http://$domain/");
	
	$domainContentLength = length($response->content)
}

###########################################################################
sub printResponse 
###########################################################################
{
	my $r = shift;

	if ($r->code eq 200 && ! $nocolor) { print color 'green'; }
	if (($r->code eq 301 || $r->code eq 302) && ! $nocolor) { print color 'blue'; }
	if ($r->code >= 400 && $r->code < 500 && ! $nocolor) { print color 'yellow'; }
	if ($r->code eq 500 && ! $nocolor) { print color 'red'; }

	if(length($r->content) != $domainContentLength)
	{
		print "[FOUND] $curDomain\n";
	}	
}

