use Test::More qw(no_plan);

use File::Temp qw/ tempfile tempdir /;
use LWP::UserAgent::WithCache;

my $tempdir = tempdir( CLEANUP => 1 );

my $ua = LWP::UserAgent::WithCache->new({ cache_root => $tempdir });

my $res;
$res  = HTTP::Response->parse(<<'EOF');
HTTP/1.1 200 OK
Connection: close
Date: Tue, 09 Oct 2007 06:03:01 GMT
Accept-Ranges: bytes
ETag: "3bf60b-ed-61bb4b40"
Server: Apache
Content-Length: 237
Content-Type: text/css
Last-Modified: Wed, 03 Oct 2007 00:00:13 GMT
Client-Date: Mon, 08 Oct 2007 12:52:55 GMT
Client-Peer: 59.106.15.125:80
Client-Response-Num: 1

/* This is the StyleCatcher theme addition. Do not remove this block. */
/* Selected Layout:  */
@import url(base_theme.css);
@import url(http://mt.qootas.org/mt/mt-static/themes/minimalist-red/screen.css);
/* end StyleCatcher imports */
EOF

my $uri = 'http://www.example.com/styles.css';
$ua->set_cache($uri, $res);
$res = $ua->get('http://www.example.com/styles.css');

is ($res->code, 200);
