#!/usr/bin/perl
use Redis;
use threads;
use Async;

$redis   = Redis->new || die "Failed to connect to Redis";

# forever
while(1) {
  my $work_count = $redis->llen('work');

  # if we actually have work
  if($work_count > 0) {
    # pop a ticker off the list
    my $job = $redis->rpop('work');
    if($job) {
      $proc = Async->new( sub {
        system("cd lib && ./indexer.pl $job");
      });
    }
  }
  sleep(2);
}