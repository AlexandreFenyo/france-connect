#!/usr/bin/perl -W

use URI::Query;

my %qq = URI::Query->new($ENV{"REQUEST_URI"})->hash;
print "Content-type: text/html\nLocation: ".$qq{"post_logout_redirect_uri"}."\n\n";

__END__
