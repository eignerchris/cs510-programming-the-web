use IO::Socket::INET;
use URI;
require WWW::RobotRules;

# performs a robots.txt-obeying HTTP get request to a url and returns (headers, source) tuple
sub get_using_robots {
  my $robotsrules = new WWW::RobotRules 'MOMspider/1.0';
  my $url         = URI->new($_[0]);
  my $host        = $url->host;
  my $path        = $url->path;

  # check cache for robots.txt first
  my $robots_txt = $redis->get("robots:$host");

  # if no cached version, fetch it, then cache it for next time
  unless($robots_txt) {
    my ($_, $robots_txt) = &get("$host/robots.txt");
    $robotsrules->parse($_[0], $robots_txt);
    $redis->set("robots:$host" => $robots_txt);
  }
  
  # if allowed by robots.txt file, make request
  # else just return empty strings
  if($robotsrules->allowed($url)) {
    my($headers, $body) = &get($_[0]);
    return ($headers, $body);
  } else {
    return("", "");
  }
}

# performs an HTTP get request to a url and returns (headers, source) tuple
sub get {
  # setup various args for socket
  if($_[0] =~ /http/i) {
    $arg = $_[0];
  } else {
    $arg = "http://$_[0]";
  }

  my $uri  = URI->new($arg);
  my $host = $uri->host;
  my $path = $uri->path;
  
  # open a socket connection to the specified host
  my $socket = new IO::Socket::INET PeerHost => $host, PeerPort => '80', Proto => 'tcp';

  # perform an HTTP GET request for the path
  print $socket "GET $path HTTP/1.0\nHost: $host\nUser-Agent: EignerBot - PSU grad student - contact: eignerchris@gmail.com\n\n";
  my @response = <$socket>;
  close $socket;

  # split headers and body and return
  return (split("\r\n\r\n", join('', @response), 2));
};


sub spider {
  my $url    = $_[0];
  my $ticker = uc($_[1]);
  my $level  = $_[2];
  my $uri    = URI->new($url);
  my $host   = $uri->host;
  $host      = "http://$host" unless $host =~ /http/i;

  return unless defined($url);
  return unless defined($level);
  return unless defined($ticker);
  return if($url =~ /https/i);
  return if($url =~ /doubleclick/i);
  return if($url =~ /javascript/i);
  return if($url eq "#");
  return if($url eq "");
  return if($url eq "*");

  print "[Indexer $ticker]: indexing $url at level $level\n";

  my($headers, $body) = &get_using_robots($url);
  $redis->sadd('visited', $url);

  # TODO: whitespace in ticker?
  if($headers =~ /200 OK/) {
    if($body =~ /($ticker)/g) {
      $redis->sadd( "tickers", "$ticker" );
      $redis->sadd( "$ticker", "$url" );
    }

    my $extor = HTML::SimpleLinkExtor->new();
    $extor->parse($body);
    my @hrefs = $extor->a;

    foreach my $link (@hrefs) {
      $link = "$host$link" if($link !~ /http/);

      if(($level < $LEVEL_MAX) and (&already_visited($link) eq 0)) {
        &spider($link, $ticker, $level+1);
      }
    }
  }
  return;
}

sub already_visited {
  my $url = $_[0];
  $redis->sismember('visited', $url);
}

1;