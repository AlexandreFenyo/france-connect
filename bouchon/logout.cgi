#!/bin/zsh

echo -n $REQUEST_URI | sed 's/.*post_logout_redirect_uri=//' | sed 's/&.*//' | perl -MURI::Escape -e 'print uri_unescape(<>);' | read LOC
echo Content-type: text/html
echo Location: $LOC
echo
