#!/usr/bin/perl -W

print "Content-type: application/json; charset=utf-8\n\n";

print '{
  "sub":"YWxhY3JpdMOp",
  "acr": "eidas2",
  "gender":"male",
  "birthdate":"1981-04-21",
  "birthcountry":"99100",
  "birthplace":"49007",
  "given_name":"Éric",
  "family_name":"Mercier",
  "email":"eric.mercier@france.fr",
  "address":{"formatted":"26 rue Désaix, 75015 Paris","street_address":"26 rue Désaix","locality":"Paris","region":"Île-de-France","postal_code":"75015","country":"France"}
}';

__END__
