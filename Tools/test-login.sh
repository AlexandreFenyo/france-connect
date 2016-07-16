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

# étape 1
get http://127.0.0.1/user

# étape 2
get $LOC

# étape 3
get $LOC

# étape 4
get "https://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip"

# étape 5
get $LOC

# étape 6
URL=$LOC
get $URL

# étape 7
post $URL 'identifier=1234567891011&password=123'

# étape 8
get $LOC

# étape 9
get $LOC

# étape 10
get $LOC

# étape 11
get $LOC

# étape 12
get $LOC

# étape 13
post $BASE/confirm-redirect-client 'accept=Continuer+sur+RSI'

# étape 14
get $LOC

# étape 15
get $LOC
fgrep 'userInfo =' tmp/output-$I.txt || echo ERREUR
