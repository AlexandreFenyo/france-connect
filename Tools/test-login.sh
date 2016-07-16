#!/usr/bin/zsh

I=0

setopt NULLGLOB
rm -f tmp/{cookies-,output-,logs-}*.txt

preproc() {
  I=$(( I + 1 ))
  echo "step $I $1: $2"
  echo $2 | sed 's%\(^[a-z]*://[^/]*\).*%\1%' | read BASE
}

postproc() {
  egrep '^Location:' tmp/headers-$I.txt | sed 's/^Location: //' | read LOC
  echo $LOC | egrep '^https?://' >& /dev/null || LOC=$BASE$LOC
}

get() {
  preproc GET $1
  curl -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt "$1" >& tmp/logs-$I.txt
  postproc
}

post() {
  preproc POST $1
  curl -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt --data-binary "$2" "$1" >& tmp/logs-$I.txt
  postproc
}

# �tape 1
get http://127.0.0.1/user

# �tape 2
# http://127.0.0.1/openid_connect_login
get $LOC

# �tape 3
# https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?response_type=code&client_id=[CLIENT_ID]&scope=openid+gender+birthdate+birthcountry+birthplace+given_name+family_name+email+address+preferred_username+phone&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&nonce=2d5fced1cf327&state=2f1e28e1a4aa6
get $LOC

# �tape 4
# https://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip
get "$BASE/call?provider=dgfip"

# �tape 5
# https://fip1.integ01.dev-franceconnect.fr/user/authorize?state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5&nonce=6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57&response_type=code&client_id=5612e79ecc8683b8d386994c01835cae&redirect_uri=https%3A%2F%2Ffcp.integ01.dev-franceconnect.fr%2Foidc_callback&scope=openid%20profile%20email%20address%20phone%20birth
get $LOC

# �tape 6
# https://fip1.integ01.dev-franceconnect.fr/my/login?return_url=%2Fuser%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D5612e79ecc8683b8d386994c01835cae%26scope%3Dopenid%2520profile%2520email%2520address%2520phone%2520birth%26redirect_uri%3Dhttps%253A%252F%252Ffcp.integ01.dev-franceconnect.fr%252Foidc_callback%26state%3Db3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5%26nonce%3D6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
URL=$LOC
get $URL

# �tape 7
# https://fip1.integ01.dev-franceconnect.fr/my/login?return_url=%2Fuser%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D5612e79ecc8683b8d386994c01835cae%26scope%3Dopenid%2520profile%2520email%2520address%2520phone%2520birth%26redirect_uri%3Dhttps%253A%252F%252Ffcp.integ01.dev-franceconnect.fr%252Foidc_callback%26state%3Db3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5%26nonce%3D6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
post $URL 'identifier=1234567891011&password=123'

# �tape 8
# https://fip1.integ01.dev-franceconnect.fr/user/authorize?response_type=code&client_id=5612e79ecc8683b8d386994c01835cae&scope=openid%20profile%20email%20address%20phone%20birth&redirect_uri=https%3A%2F%2Ffcp.integ01.dev-franceconnect.fr%2Foidc_callback&state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5&nonce=6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
get $LOC

# �tape 9
# https://fcp.integ01.dev-franceconnect.fr/oidc_callback?code=bcc7c5b83411d15d21c9d6945a61d2a8&state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5
get $LOC

# �tape 10
# https://fcp.integ01.dev-franceconnect.fr/redirect-service-provider
get $LOC

# �tape 11
# https://fcp.integ01.dev-franceconnect.fr/login
get $LOC

# �tape 12
# https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?response_type=code&client_id=[CLIENT_ID]&scope=openid%20gender%20birthdate%20birthcountry%20birthplace%20given_name%20family_name%20email%20address%20preferred_username%20phone&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&nonce=2d5fced1cf327&state=2f1e28e1a4aa6&fc_internal=true
get $LOC

# �tape 13
# https://fcp.integ01.dev-franceconnect.fr/confirm-redirect-client
post $BASE/confirm-redirect-client 'accept=Continuer+sur+RSI'

# �tape 14
# http://127.0.0.1/openid_connect_login?code=17522a71ea0352b0b705029eb47e014a0ce5ef3b76bb582d30e22a33dbda1394&state=2f1e28e1a4aa6
get $LOC

# �tape 15
# http://127.0.0.1/user
get $LOC
fgrep 'userInfo =' tmp/output-$I.txt || echo ERREUR
