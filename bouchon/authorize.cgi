#!/bin/zsh

echo Content-type: text/html
echo -n "Location: "
echo -n $REQUEST_URI | sed 's/.*redirect_uri=//' | sed 's/&.*//' | perl -MURI::Escape -e 'print uri_unescape(<>);' | read LOC
echo -n $REQUEST_URI | sed 's/.*state=//' | sed 's/&.*//' | read STATE
echo -n $REQUEST_URI | sed 's/.*nonce=//' | sed 's/&.*//' | read NONCE
echo "$LOC?code=code$NONCE&state=$STATE"
echo
