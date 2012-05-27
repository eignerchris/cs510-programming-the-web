#!/usr/bin/perl
# *** Exercise 3
# *** Author: Chris Eigner
# *** An HTTP client that accepts a URL at the command line, 
# *** recursively retrieves all web pages to which it linkes,
# *** and counts lines and flags script tags with an asterisk

use IO::Socket::INET;
use URI;

print "\nUsage: ./exercise3.pl URL\n\n" and exit if (@ARGV == 0);

$level = -1;
&analyze(@ARGV[0]);

# performs an HTTP get request to a url and returns (headers, source) tuple
sub get {
  # setup various args for socket
  if($_[0] =~ /http/) {
    $url  = URI->new($_[0]);
    $host = $url->host;
    $path = $url->path;
  } else {
    $host = $current_host;
    $path = $_[0];
  }
  
  # open a socket connection to the specified host
  my $socket = new IO::Socket::INET PeerHost => $host, PeerPort => '80', Proto => 'tcp';

  # perform an HTTP GET request for the path
  print $socket "GET $path HTTP/1.0\nHost: $host\n\n";

  # get the response from the socket and close
  my @response = <$socket>;
  close $socket;

  # split headers and body and return
  return (split("\r\n\r\n", join('', @response), 2));
};

sub analyze {
  $level += 1;

  # do our get request
  my $url                = $_[0];
  my ($headers, $source) = &get($url);

  # only do analysis if document fetch was successful
  if($headers =~ /200 OK/) {
    my $line_count   = &line_count($source);
    my $script_count = &script_count($source);

    # print useful output
    # for (0..$level-1) { print "\t" };
    # print "LEVEL $level:\t$line_count\t$url";
    # for (1..$script_count) { print "*" };
    # print "\n";

    # extract hrefs from source and analyze each
    foreach $line (split("\n", $source)) {
      if ($line =~ /href="(http:\/\/)?([\w\.]+)(\/[\w\.\/\~\=\&]*)"/i) {
        # only analyze 4 levels deep
        ($level < 4) ? &analyze("$1$2$3") : return;
      }
    }
  }

  $level -= 1;
  return if $level == 0;
};

# counts lines in string
# arg: string
# returns integer
sub line_count {
  my $count = split("\n", $_[0]);
  return $count;
}

# counts script tags in string
# arg: string
# returns integer
sub script_count {
  my $source = $_[0];
  my $count  = 0;

  foreach $line (split("\n", $source)) {
    $count += 1 if ($line =~ /<script ?/i);
  }
  return $count;
}