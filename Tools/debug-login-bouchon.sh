#!/usr/bin/zsh

I=0

setopt NULLGLOB
rm -f tmp/{headers-,cookies-,output-,logs-}*.txt
mkdir -p tmp

preproc() {
#  echo -n appuyez sur Entrée: ; read X
  I=$(( I + 1 ))
  echo "step $I $1: $2"
  echo $2 | sed 's%\(^[a-z]*://[^/]*\).*%\1%' | read BASE
}

postproc() {
  egrep '^Location:' tmp/headers-$I.txt | sed 's/^Location: //' | sed 's/\r//'g | read LOC
  echo $LOC | egrep '^https?://' >& /dev/null || LOC=$BASE$LOC
}

get() {
  preproc GET $1
  curl -k -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt "$1" >& tmp/logs-$I.txt
  postproc
}

post() {
  preproc POST $1
  curl -k -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt --data-binary "$2" "$1" >& tmp/logs-$I.txt
  postproc
}

# étape 1
get https://demo-service.fenyo.net/user

# étape 2
# https://FQDN-SERVICE/openid_connect_login
get $LOC

# étape 3
# http://FQDN-BOUCHON:8080/api/v1/authorize?response_type=code&client_id=[CLIENT_ID]&scope=openid+gender+birthdate+birthcountry+birthplace+given_name+family_name+email+address+preferred_username+phone&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&nonce=2d5fced1cf327&state=2f1e28e1a4aa6
get $LOC

# étape 4
# https://FQDN-SERVICE/openid_connect_login?code=17522a71ea0352b0b705029eb47e014a0ce5ef3b76bb582d30e22a33dbda1394&state=2f1e28e1a4aa6
get $LOC

# étape 15
# http://FQDN-SERVICE/user
get $LOC
fgrep JSON tmp/output-$I.txt || echo ERREUR

exit 0

