#!/bin/zsh

echo "Content-type: application/json; charset=utf-8"
echo

cat <<EOF
{
    "sub":"YWxhY3JpdMOp",
    "gender":"male",
    "birthdate":"1981-04-21",
    "birthcountry":"99100",
    "birthplace":"49007",
    "given_name":"Eric",
    "family_name":"Mercier",
    "email":"eric.mercier@france.fr",
    "address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}
  }
EOF
