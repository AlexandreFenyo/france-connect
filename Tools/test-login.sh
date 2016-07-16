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
get $LOC

# �tape 3
get $LOC

# �tape 4
get "https://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip"

# �tape 5
get $LOC

# �tape 6
URL=$LOC
get $URL

# �tape 7
post $URL 'identifier=1234567891011&password=123'

# �tape 8
get $LOC

# �tape 9
get $LOC

# �tape 10
get $LOC

# �tape 11
get $LOC

# �tape 12
get $LOC

# �tape 13
post $BASE/confirm-redirect-client 'accept=Continuer+sur+RSI'

# �tape 14
get $LOC

# �tape 15
get $LOC
fgrep 'userInfo =' tmp/output-$I.txt || echo ERREUR
