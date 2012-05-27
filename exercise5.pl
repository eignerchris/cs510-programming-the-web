#!/usr/bin/perl
# *** Exercise 5
# *** Author: Chris Eigner
# *** an HTTP client that maintains cookies

use IO::Socket::INET;
use URI;
use Date::Parse;

print "\nUsage: ./exercise5.pl URL\n\n" and exit if (@ARGV == 0);

# setup uri and host vars for use later
$url  = @ARGV[0];
$uri  = URI->new($url);
$host = $uri->host;

# expire cookies for given domain
&expire_cookies("$host.cookie");

# make the request for the supplied URL
($headers, $body) = &get($url);
print "Response:\n$body";

# collect non-session set-cookie headers
@header_lines = split("\r\n", $headers);
for $header(@header_lines) {
  push(@cookies, $header) if $header =~ /Set-Cookie: / && $header =~ /expires/;
}

# write all non-session cookies to file for use by &get
if(length(@cookies) > 0) {
  print "Cookies found in response! Writing to $host.cookie...";
  open FILE, ">", "$host.cookie";
  for $cookie(@cookies) {
    $cookie =~ s/Set-Cookie: //g;
    print FILE "$cookie\n"; 
  };
  close FILE;
  print "done\n";
}

# performs an HTTP get request to a url and returns (headers, source) tuple
# checks for existence of $domain.cookie file and sets cookie headers
sub get {
  my $url  = URI->new($_[0]);
  my $host = $url->host;
  my $path = $url->path;

  my $socket = new IO::Socket::INET PeerHost => $host, PeerPort => '80', Proto => 'tcp';

  $header = "GET $path HTTP/1.0\nHost: $host";

  # if cookie file exists, add cookie headers
  if(-e "$host.cookie") {
    print "Cookie file found! Adding Cookie headers...\n";
    open FILE, "<", "$host.cookie";
    while (my $line = <FILE>) { 
      chomp($line);
      $header .= "\nCookie: $line"
    }
    close FILE;
  }

  $header .= "\n\n";

  print "Request:\n$header";

  # make the request
  print $socket $header;
  my @response = <$socket>;
  close $socket;

  return (split("\r\n\r\n", join('', @response), 2));
};

# opens $domain.cookie file and collects those with un-expired values
# writes un-expired values to new file
sub expire_cookies {
  if(-e "$_[0]") {
    print "Expiring cookies for $_[0]...";

    open FILE, "+<", $_[0];
    open NEW_FILE, "+>", "$_[0].new";

    $now = str2time(`date`);

    while (my $line = <FILE>) {
      my($key, $expire_time) = split("expires=", $line, 2);
      my $expire_time        = str2time($expire_time);

      print NEW_FILE $line if($expire_time > $now);
    }

    # tidy up
    close FILE;
    close NEW_FILE;
    rename("$_[0].new", $_[0]);
    unlink("$_[0].new");
    print "done\n"
  }
}