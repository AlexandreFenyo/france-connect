#!/bin/zsh

export PATH=/usr/local/bin:$PATH

KEY=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
IV=87b7225d16ea2ae1f41d0b13fdce9bba

echo Content-type: text/html
echo Cache-Control: no-store
echo Pragma: no-cache
echo
echo
echo "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Demo France Connect</title></head><body>"
echo "$QUERY_STRING" | sed 's/.*info=\([a-z0-9]*\).*/\1/' | perl -pe 's/([0-9a-f]{2})/chr hex $1/gie' | openssl aes-256-cbc -d -K $KEY -iv $IV | read IDENT
echo "$IDENT" | jq '.given_name, .family_name' | xargs echo | read NAME
echo '<script src="https://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js"></script>'
echo '<div style="color: #000000; background-color: #000ccc" id="fconnect-profile" data-fc-logout-url="logout.cgi"><br/>'
echo "<a href='#'>$NAME</a><br/>&nbsp;</div>"
echo "Vous &ecirc;tes authentifi&eacute; : $IDENT"
echo "<p/>IMPORTANT : pour assurer la protection anti-rejeu et contre le saut de session, le programmeur doit v&eacute;rifier que nonce et state correspondent bien &agrave; ceux de la requ&ecirc;te avant d'exploiter les informations d'identification de l'utilisateur."
echo "<hr/>Code source de identite.cgi :<pre>"
cat << EOF
#!/bin/zsh
KEY=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
IV=87b7225d16ea2ae1f41d0b13fdce9bba
echo Content-type: text/html
echo Cache-Control: no-store
echo Pragma: no-cache
echo
echo
echo "&lt;html>&lt;head>&lt;meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>&lt;title>Demo France Connect&lt;/title>&lt;/head>&lt;body>"
echo "\$QUERY_STRING" | sed 's/.*info=\([a-z0-9]*\).*/\1/' | perl -pe 's/([0-9a-f]{2})/chr hex \$1/gie' | openssl aes-256-cbc -d -K \$KEY -iv \$IV | read IDENT
echo "\$IDENT" | jq '.given_name, .family_name' | xargs echo | read NAME
echo '&lt;script src="https://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js">&lt;/script>'
echo '&lt;div style="color: #000000; background-color: #000ccc" id="fconnect-profile" data-fc-logout-url="logout.cgi">&lt;br/>'
echo "&lt;a href='#'>\$NAME&lt;/a>&lt;br/>&nbsp;&lt;/div>"
echo "Vous &ecirc;tes authentifi&eacute; : \$IDENT"
echo "&lt;p/>IMPORTANT : pour assurer la protection anti-rejeu et contre le saut de session, le programmeur doit v&eacute;rifier que nonce et state correspondent bien &agrave; ceux de la requ&ecirc;te avant d'exploiter les informations d'identification de l'utilisateur."
echo "&lt;/body>&lt;/html>"
</pre>
<hr/>
<a href="index.cgi">retour &agrave; l'accueil</a>
</body></html>
EOF
