#!/usr/bin/perl
use lib '.';
use Helpers;
use Redis;
use HTML::SimpleLinkExtor;
use threads;
use warnings;

# setup environment and globals
my $ticker = $ARGV[0];
$redis     = Redis->new || die "Failed to connect to Redis";
@sources   = $redis->smembers("sources");
$LEVEL_MAX = 2;

# reset visited for development
$redis->del('visited');

print "Starting indexer for $ticker\n";

$redis->set("indextime:$ticker", time);

my @children;

foreach $source(@sources) {
  my $pid = fork();
  if ($pid) {
    # parent
    push(@children, $pid);
  } elsif ($pid == 0) {
    # child
    &do_spider($source, $ticker, 0);
    exit 0;
  } 
}
 
foreach (@children) {
  waitpid($_, 0);
}
 
print "Done indexing $ticker\n";
 
sub do_spider {
  my $source = $_[0];
  my $ticker = $_[1];
  my $level  = $_[2];
  &spider($source, $ticker, 0);
}