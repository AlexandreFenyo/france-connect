#!/usr/bin/zsh

I=0

setopt NULLGLOB
rm -f tmp/{cookies-,output-,logs-}*.txt

prepare() {
  I=$(( I + 1 ))
  echo "step $I GET: $1"
  echo $1 | sed 's%\(^[a-z]*://[^/]*\).*%\1%' | read BASE
}

get() {
  prepare $1
  curl -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt "$1" >& tmp/logs-$I.txt
  egrep '^Location:' tmp/headers-$I.txt | sed 's/^Location: //' | read LOC
}

post() {
  prepare $1
  curl -vvvv -b tmp/cookies-$(( I - 1 )).txt -c tmp/cookies-$I.txt -D tmp/headers-$I.txt -o tmp/output-$I.txt --data-binary "$2" "$1" >& tmp/logs-$I.txt
  egrep '^Location:' tmp/headers-$I.txt | sed 's/^Location: //' | read LOC
}

# step 1
get http://127.0.0.1/user

# step 2
get http://127.0.0.1/openid_connect_login

# step 3
get $LOC

# step 4
get "https://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip"

# step 5
get $LOC

# step 6
URL=$BASE$LOC
get $URL

# step 7
post $URL 'identifier=1234567891011&password=123'

# step 8
get $BASE$LOC

# step 9
get $LOC

# step 10
get $BASE$LOC

# step 11
get $BASE$LOC

# step 12
get $BASE$LOC

# step 13
post $BASE/confirm-redirect-client 'accept=Continuer+sur+RSI'

# step 14
get $LOC

# step 15
get $LOC
fgrep 'userInfo =' tmp/output-$I.txt || echo ERREUR

