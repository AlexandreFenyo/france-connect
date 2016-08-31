#!/usr/bin/perl -W

use Crypt::JWT qw(encode_jwt);
use URI::Query;

my %qq = URI::Query->new(<>)->hash;
my $nonce = $qq{"code"};
$nonce =~ s/^code//;
my $token = '{"aud":"1111111111111111111111111111111111111111111111111111111111111111", "exp":'.(time + 3600).', "iat":'.time.', "iss":"http://fenyo.net/fc-idp", "sub":"YWxhY3JpdMOp", "idp":"FC", "nonce":"'.$nonce.'"}';
my $jws_token = encode_jwt(payload=>$token, extra_headers=>{typ=>'JWT'}, alg=>'HS256', key=>'2222222222222222222222222222222222222222222222222222222222222222');
print "Content-type: application/json; charset=utf-8\n\n{'access_token':'$jws_token', 'token_type':'Bearer', 'expires_in':3600, 'id_token':'$jws_token'}\n";

__END__
