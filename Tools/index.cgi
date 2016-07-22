#!/bin/zsh

KEY=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
IV=87b7225d16ea2ae1f41d0b13fdce9bba

echo Content-type: text/html
echo Cache-Control: no-store
echo Pragma: no-cache
echo
echo

openssl rand -hex 16 | head -c 16 | read STATE
openssl rand -hex 16 | head -c 32 | read NONCE
echo "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Demo France Connect</title></head><body>"
echo -n "http://fenyo.net/fc/identite.cgi?nonce=$NONCE&state=$STATE" | openssl aes-256-cbc -K $KEY -iv $IV | hexdump -v -e '1/1 "%02x"' | read HEX
echo "cliquez sur ce lien pour vous authentifier puis revenir &agrave; ce service :<br/>"
echo "<a href='http://127.0.0.1/idp?msg=$HEX'>http://127.0.0.1/idp?msg=$HEX</a>"
echo "<hr/>Code source de index.cgi:<pre>"
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
openssl rand -hex 16 | head -c 16 | read STATE
openssl rand -hex 16 | head -c 32 | read NONCE
echo -n "http://fenyo.net/fc/identite.cgi?nonce=\$NONCE&state=\$STATE" | openssl aes-256-cbc -K \$KEY -iv \$IV | hexdump -v -e '1/1 "%02x"' | read HEX
echo "cliquez sur ce lien pour vous authentifier puis revenir &agrave; ce service :&lt;br/>"
echo "&lt;a href='http://127.0.0.1/idp?msg=\$HEX'>http://127.0.0.1/idp?msg=\$HEX&lt;/a>&lt;/body>&lt;/html>"
</body></html>
EOF

