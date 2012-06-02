#!/usr/bin/perl
use Redis;

$redis = Redis->new || die "Failed to connect to Redis";

my @hosts = $redis->smembers('hosts');

print "host, hits, misses\n";

for $host(@hosts) {
  my $miss_count = $redis->get("misses:$host") || 0;
  $host          = "$host/" unless(substr($host,length($host)-1,1) eq "\\");
  my $hit_count  = $redis->get("hits:$host") || 0; 
  print "$host, $hit_count, $miss_count\n";
}