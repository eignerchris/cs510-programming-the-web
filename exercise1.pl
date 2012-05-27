#!/usr/bin/perl

# *** Exercise 1
# *** Author: Chris Eigner
# ***
# *** an HTTP client that accepts a URL at the command
# *** line, retrieves the web page and counts lines,
# *** words and characters
#

$url = @ARGV[0];

if($url !~ /http/) {
  $url = 'http://'.$url;
};

print "Chris Eigner\n";
print `lynx -source $url | wc`;