#!/usr/bin/perl -W

use URI::Query;

my %qq = URI::Query->new($ENV{"REQUEST_URI"})->hash;
print "Content-type: text/html\nLocation: ".$qq{"redirect_uri"}."?code=code".$qq{"nonce"}."&state=".$qq{"state"}."\n\n";

__END__
