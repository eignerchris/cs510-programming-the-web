#!/usr/bin/perl
# *** Exercise 2
# *** Author: Chris Eigner
# ***
# *** an HTTP client that accepts a URL at the command
# *** line, retrieves the web page and all web pages,
# *** to which it directly links and counts lines,
# *** words, and characters for each
#

use IO::Socket::INET;
use URI;

print "\nUsage: ./exercise2.pl URL\n\n" and exit if (@ARGV == 0);

# get host and path from supplied argument
$urlarg = @ARGV[0];

# add protocol if it's missing
if($urlarg !~ /http/){
  $urlarg = 'http://'.$urlarg;
};

# set our target
$url  = URI->new($urlarg);
$targethost = $url->host;
$targetpath = $url->path;

# open a socket connection to target host
$socket = new IO::Socket::INET ( PeerHost => $targethost, PeerPort => '80', Proto => 'tcp' );

# perform an HTTP GET request for the path
print $socket <<EOL;
GET $targetpath HTTP/1.0
Host: $targethost

EOL

# get the response from the socket and close
@response = <$socket>;
close($socket);

# extract all hrefs from the returned document source code
foreach $line (@response) {
  if($line =~ /href="(http:\/\/)?([\w\.]+)(\/[\w\.\/\~\=\&]*)"/i) {
    push(@hrefs, "$1$2$3");
  };
};

# push the original target to our array for analysis below
unshift(@hrefs, $url->as_string);

# iterate over all links and process
foreach $href (@hrefs) {
  # if it's an external resource
  if($href =~ /http/) {
    $url  = URI->new($href);
    $host = $url->host;
    $path = $url->path;
  }
  # if it's an internal resource
  else {
    $host = $targethost;
    $path = $href;
  }
  
  # open a socket connection to the specified host
  $socket = new IO::Socket::INET ( PeerHost => $host, PeerPort => '80', Proto => 'tcp' );

# perform an HTTP GET request for the path
  print $socket <<EOL;
GET $path HTTP/1.0
Host: $host

EOL

  # get the response from the socket and close
  @response = <$socket>;
  close($socket);

  # split headers from response body
  ($headers, $source) = split("\r\n\r\n", join('', @response), 2);

  # only do word, line, char count if connection to url was successful
  if($headers =~ /200 OK/) {
    # never got echoing $source to bash for wc working. needed escaping.
    # create tmpfile and pipe to wc instead
    open FILE, ">", "tmp.html";
    print FILE $source;

    # cat file instead of wc filename so our output is formatted correctly ( no filename in output )
    chomp($counts = `cat tmp.html | wc`);
    print "$counts $href\n";
  };
}

# cleanup
`rm tmp.html`
