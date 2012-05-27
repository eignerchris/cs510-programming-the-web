#!/usr/bin/perl
# *** Exercise 4
# *** Author: Chris Eigner
# *** an HTTP client that logs you into a page
# *** protected by basic authentication

use IO::Socket::INET;
use URI;
use MIME::Base64;

print "\nUsage: ./exercise4.pl URL\n\n" and exit if (@ARGV == 0);

$url              = @ARGV[0];
($headers, $body) = &get($url);
($headers, $body) = &get($url, &get_from_user('Username'), &get_from_user('Password')) if($headers =~ /401 Authorization/);

print "=== HEADERS ===\n$headers\n\n=== BODY ===\n$body\n";

sub get_from_user {
  print "\n$_[0]: ";
  chomp(my $val = <STDIN>);
  return $val;
}

# performs an HTTP get request to a url and returns (headers, source) tuple
sub get {
  my $url  = URI->new($_[0]);
  my $host = $url->host;
  my $path = $url->path;
  
  # handle basic auth params if included in arg list
  my $encoded = encode_base64("$_[1]:$_[2]") if($_[1] && $_[2]);

  # open a socket connection to the specified host
  my $socket = new IO::Socket::INET PeerHost => $host, PeerPort => '80', Proto => 'tcp';

  # perform an HTTP GET request for the path
  print $socket "GET $path HTTP/1.0\nHost: $host";
  
  # write authorization header to socket if username and password supplied {
  print $socket "\nAuthorization: Basic $encoded" if($_[1] && $_[2]);

  print $socket "\n\n";

  # get the response from the socket and close
  my @response = <$socket>;
  close $socket;

  return (split("\r\n\r\n", join('', @response), 2));
};