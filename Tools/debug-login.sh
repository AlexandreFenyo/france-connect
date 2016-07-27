#!/usr/bin/zsh

I=0

setopt NULLGLOB
rm -f tmp/{headers-,cookies-,output-,logs-}*.txt
mkdir -p tmp

preproc() {
  echo -n appuyez sur Entrée: ; read X
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
# http://127.0.0.1/openid_connect_login
get $LOC

# étape 3
# on contacte l'authorization endpoint de France Connect
# on demande un type de réponse (response_type) valant "code" : on attend donc un scénario de type "Authorization Code Flow".
# on fournit une valeur de "state" pour suivre cet échange avec France Connect
# c'est le seul type de flow implémenté par MitreID Connect pour les clients : cf. https://github.com/mitreid-connect/OpenID-Connect-Java-Spring-Server/wiki/Features
# cf tableau dans la section 3 de http://openid.net/specs/openid-connect-core-1_0.html
# https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?response_type=code&client_id=[CLIENT_ID]&scope=openid+gender+birthdate+birthcountry+birthplace+given_name+family_name+email+address+preferred_username+phone&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&nonce=2d5fced1cf327&state=2f1e28e1a4aa6
get $LOC

# étape 4
# https://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip
get "$BASE/call?provider=dgfip"

# étape 5
# on contacte l'authorization endpoint du fournisseur d'identité
# France Connect nous fait demander un type de réponse (response_type) valant "code" : il y a donc un scénario de type "Authorization Code Flow" entre France Connect et le fournisseur d'identité choisi (DGFIP).
# cf tableau dans la section 3 de http://openid.net/specs/openid-connect-core-1_0.html
# https://fip1.integ01.dev-franceconnect.fr/user/authorize?state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5&nonce=6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57&response_type=code&client_id=5612e79ecc8683b8d386994c01835cae&redirect_uri=https%3A%2F%2Ffcp.integ01.dev-franceconnect.fr%2Foidc_callback&scope=openid%20profile%20email%20address%20phone%20birth
get $LOC

# étape 6
# https://fip1.integ01.dev-franceconnect.fr/my/login?return_url=%2Fuser%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D5612e79ecc8683b8d386994c01835cae%26scope%3Dopenid%2520profile%2520email%2520address%2520phone%2520birth%26redirect_uri%3Dhttps%253A%252F%252Ffcp.integ01.dev-franceconnect.fr%252Foidc_callback%26state%3Db3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5%26nonce%3D6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
URL=$LOC
get $URL

# étape 7
# https://fip1.integ01.dev-franceconnect.fr/my/login?return_url=%2Fuser%2Fauthorize%3Fresponse_type%3Dcode%26client_id%3D5612e79ecc8683b8d386994c01835cae%26scope%3Dopenid%2520profile%2520email%2520address%2520phone%2520birth%26redirect_uri%3Dhttps%253A%252F%252Ffcp.integ01.dev-franceconnect.fr%252Foidc_callback%26state%3Db3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5%26nonce%3D6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
post $URL 'identifier=1234567891011&password=123'

# étape 8
# on contacte l'authorization endpoint du fournisseur d'identité
# https://fip1.integ01.dev-franceconnect.fr/user/authorize?response_type=code&client_id=5612e79ecc8683b8d386994c01835cae&scope=openid%20profile%20email%20address%20phone%20birth&redirect_uri=https%3A%2F%2Ffcp.integ01.dev-franceconnect.fr%2Foidc_callback&state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5&nonce=6ebb8ad487e8cbab38594aad5d040bac2ffbbb887b30787a8005b56f342ebf57
get $LOC

# étape 9
# https://fcp.integ01.dev-franceconnect.fr/oidc_callback?code=bcc7c5b83411d15d21c9d6945a61d2a8&state=b3c07b34d26ac30e8f45efda0feb78bd31b10bc9d5e3e33f8e2ebff26cb0a1a5
get $LOC

# étape 10
# https://fcp.integ01.dev-franceconnect.fr/redirect-service-provider
get $LOC

# étape 11
# https://fcp.integ01.dev-franceconnect.fr/login
get $LOC

# étape 12
# on contacte l'authorization endpoint de France Connect
# https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?response_type=code&client_id=CLIENT_ID&scope=openid%20gender%20birthdate%20birthcountry%20birthplace%20given_name%20family_name%20email%20address%20preferred_username%20phone&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&nonce=2d5fced1cf327&state=2f1e28e1a4aa6&fc_internal=true
get $LOC

# étape 13
# France Connect demande à l'utilisateur l'autorisation de fournir les informations d'identité au fournisseur de services, le navigateur fait un POST pour accepter
# https://fcp.integ01.dev-franceconnect.fr/confirm-redirect-client
post $BASE/confirm-redirect-client 'accept=Continuer+sur+RSI'

# étape 14
# le code d'autorisation est fourni au fournisseur de services - cf. traces du serveur JEE plus loin dans ce fichier pour voir les étapes réalisées par le fournisseur de services
# la valeur de "state" est bien celle fournie initialement par le fournisseur de service
# http://127.0.0.1/openid_connect_login?code=17522a71ea0352b0b705029eb47e014a0ce5ef3b76bb582d30e22a33dbda1394&state=2f1e28e1a4aa6
get $LOC

# étape 15
# http://127.0.0.1/user
get $LOC
fgrep 'userInfo =' tmp/output-$I.txt || echo ERREUR

exit 0

############################################################

Traces du serveur du fournisseur de services à l'étape 14 :
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 1 of 12 in additional filter chain; firing Filter: 'SecurityContextPersistenceFilter'
  > DEBUG: org.springframework.security.web.context.HttpSessionSecurityContextRepository - HttpSession returned null object for SPRING_SECURITY_CONTEXT
  > DEBUG: org.springframework.security.web.context.HttpSessionSecurityContextRepository - No SecurityContext was available from the HttpSession: org.apache.catalina.session.StandardSessionFacade@636c720c. A new one will be created.
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 2 of 12 in additional filter chain; firing Filter: 'WebAsyncManagerIntegrationFilter'
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 3 of 12 in additional filter chain; firing Filter: 'HeaderWriterFilter'
  > DEBUG: org.springframework.security.web.header.writers.HstsHeaderWriter - Not injecting HSTS header since it did not match the requestMatcher org.springframework.security.web.header.writers.HstsHeaderWriter$SecureRequestMatcher@57fae5ed
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 4 of 12 in additional filter chain; firing Filter: 'CsrfFilter'
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 5 of 12 in additional filter chain; firing Filter: 'LogoutFilter'
  > DEBUG: org.springframework.security.web.util.matcher.AntPathRequestMatcher - Request 'GET /openid_connect_login' doesn't match 'POST /j_spring_security_logout
  > DEBUG: org.springframework.security.web.FilterChainProxy - /openid_connect_login?code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&state=359d487b371be at position 6 of 12 in additional filter chain; firing Filter: 'OIDCAuthenticationFilter'
  > DEBUG: org.springframework.security.web.util.matcher.AntPathRequestMatcher - Checking match of request : '/openid_connect_login'; against '/openid_connect_login'

Spring a détecté le retour à l'URI d'authentification munie d'un code d'autorisation, il va donc exploiter ce code fourni par ce biais par France Connect
Il invoque tout d'abord le token endpoint pour récupérer tous les tokens:

  > DEBUG: org.mitre.openid.connect.client.OIDCAuthenticationFilter - Request is to process authentication
  > DEBUG: org.mitre.openid.connect.client.OIDCAuthenticationFilter - tokenEndpointURI = https://fcp.integ01.dev-franceconnect.fr/api/v1/token
  > DEBUG: org.mitre.openid.connect.client.OIDCAuthenticationFilter - form = {grant_type=[authorization_code], code=[69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398], redirect_uri=[http://127.0.0.1/openid_connect_login], client_id=[CLIENT_ID], client_secret=[CLIENT_SECRET]}
  > DEBUG: org.apache.http.client.protocol.RequestAddCookies - CookieSpec selected: default
  > DEBUG: org.apache.http.client.protocol.RequestAuthCache - Auth cache not set in the context
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection request: [route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 0; route allocated: 0 of 5; total allocated: 0 of 10]
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection leased: [id: 2][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 0; route allocated: 1 of 5; total allocated: 1 of 10]
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Opening connection {s}->https://fcp.integ01.dev-franceconnect.fr:443
  > DEBUG: org.apache.http.impl.conn.DefaultHttpClientConnectionOperator - Connecting to fcp.integ01.dev-franceconnect.fr/194.2.208.245:443
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Connecting socket to fcp.integ01.dev-franceconnect.fr/194.2.208.245:443 with timeout 0
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Enabled protocols: [TLSv1, TLSv1.1, TLSv1.2]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Enabled cipher suites:[TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256, TLS_DHE_RSA_WITH_AES_128_CBC_SHA256, TLS_DHE_DSS_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA, TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDH_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_DSS_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA, SSL_RSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA, TLS_EMPTY_RENEGOTIATION_INFO_SCSV]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Starting handshake
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Secure session established
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  negotiated protocol: TLSv1.2
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  negotiated cipher suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  peer principal: CN=*.integ01.dev-franceconnect.fr, OU=Gandi Standard Wildcard SSL, OU=Domain Control Validated
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  peer alternative names: [*.integ01.dev-franceconnect.fr, integ01.dev-franceconnect.fr]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  issuer principal: CN=Gandi Standard SSL CA 2, O=Gandi, L=Paris, ST=Paris, C=FR
  > DEBUG: org.apache.http.impl.conn.DefaultHttpClientConnectionOperator - Connection established 192.168.100.101:21531<->194.2.208.245:443
  > DEBUG: org.apache.http.impl.conn.DefaultManagedHttpClientConnection - http-outgoing-2: set socket timeout to 30000
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Executing request POST /api/v1/token HTTP/1.1
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Target auth state: UNCHALLENGED
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Proxy auth state: UNCHALLENGED
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> POST /api/v1/token HTTP/1.1
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Accept: text/plain, application/json, application/*+json, */*
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Content-Type: application/x-www-form-urlencoded
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Content-Length: 312
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Host: fcp.integ01.dev-franceconnect.fr
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Connection: Keep-Alive
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> User-Agent: Apache-HttpClient/4.5.2 (Java/1.8.0_77)
  > DEBUG: org.apache.http.headers - http-outgoing-2 >> Accept-Encoding: gzip,deflate
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "POST /api/v1/token HTTP/1.1[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Accept: text/plain, application/json, application/*+json, */*[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Content-Type: application/x-www-form-urlencoded[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Content-Length: 312[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Host: fcp.integ01.dev-franceconnect.fr[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Connection: Keep-Alive[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "User-Agent: Apache-HttpClient/4.5.2 (Java/1.8.0_77)[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "Accept-Encoding: gzip,deflate[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 >> "grant_type=authorization_code&code=69787c02fe38177ab0322576420751681f465a79ffca00b3598ebdd5a92a3398&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&client_id=CLIENT_ID&client_secret=CLIENT_SECRET"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "HTTP/1.1 200 OK[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Server: nginx[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Date: Sun, 17 Jul 2016 15:40:30 GMT[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Content-Type: application/json; charset=utf-8[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Transfer-Encoding: chunked[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Connection: keep-alive[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Vary: Accept-Encoding[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Vary: Accept-Encoding[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Strict-Transport-Security: max-age=15768000[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "Content-Encoding: gzip[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "1e9[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "[0x1f][0x8b][0x8][0x0][0x0][0x0][0x0][0x0][0x0][0x3]<[0x90][0xc1][0x96][0xa2]0[0x10]E[0xff][0x85]uO[0x9f][0x84][0x80][0x3][0xb3]S[0xd3][0xd8]8&[0x1c]l[0x4][0xc9][0xc6][0x3]!J"i[0x19]m[0x1b][0xc9][0xfc][0xfc][0x4][0x17][0xb3][0xac]WU[0xef]U[0xdd][0xbf]N[0xc5][0xb9][0xb8][0xdd][0xe]_[0x97][0xb3][0xf8]t~9G[0xc1][0xa1][0x17]x0@[0xa1]@[0xc7]c[0xe3]U[0x8d][0x17][0x4][0x10][0xd4]a[0x83][0xd0][0xac][0xf9]y[0x9c][0xf9]n[\r][0xfd][0xe0][0xc8]Q[0xe8][0xfa]a[0xc5][0x5][0xe2][0xa2][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "[0x0][0xa8][0x1][0x82][0xb5][0xb][0x9c][0x17][0xe7]iu[0xf8][0x1a]{a[0xfd][0x16][0xa2][0xba][0x8a][0xab]U[0xc5][0xa3][0x97]Wq;H[0x9b][0x2]][0x0]^[0x1c][0xd9][0xfc]O[0x15][0xe3][0x1a][0x88][0xfd]\&r[0xfd];[0x87][0xa9][0xdc],[0xd7]m[0xbd][0xe2]S[0x1d][0xef]L[0xc][0xa9]\[0x87][0xaf]v[0xa8][0xe7][0x88]L[0xe2][0xa5]y[0xdf][0xe][0xdc]\[0xbe]7.S|[0xe9][0xf7][0xf5][0xe7][0xb6]cf[0xfe][0xd8][0xe8]m[0xd7]H[0xa8][0xb9][0x8e][0xee][0xa5][0x9b][0xab][0xda][0xf5][0xef][0xac][0xa0]`[0xa3][0xd9][0x18][0xcb]Ar[0x94][0xcb]X]$5'H[0x14][0x81][0xa5][0xc9][[0xaa][0x16]][0xb2][0x8a][0x7][0xaa]JT[0x9a][0xd4]P[0x15][0xf][0x4][0xc7]CR0EWQG[0xf0][0x1c]1[0xdc]u[0x9]n[0xce][0xa5]9[0x8d]e[0xc6][0x14]1[0xdc][0xa3][0x9a][0xc][0xc][0x13][0x8f][0x15][0xec][0x9c]d[0xac][0xa5][0xa8]|L[0x19][0xe5]>?O[0x19]I[0x91]K[0xa6][0xa2][0x96][0xe1][0xf3][0x90][0xe0]t$[0xb8]Q[0xb4][0xd8][0x81]$#~[0xa9][0xa9][0xb2][0xfb][0x88]f[0xad]J[0xf0]B[0x13]U[0xe][0xac][0xd8]![0x82][0xdf][0x10]u[0xdf][0x0]Q[0xdb].[0xc9]R[0xdb][0xdf]J{[0xc7]4[0x95][0x14][0xef][0x10][0xfb][0x88]o[0xb1][0xce]=[0xbe][0x8c]g$K[0xdd][0x4]["Yl[0xc8]r[0x90]U[0x11][0x1][0x9b][0xfb][0xa0][0xb8][0xf4][0xa8][0xe1][0xf6][0x7]2X[0x90]w[0xcb]@[0xd9][0xbd]Y[0xac][0x88][0xd5][0x89][0xfd]on[0xa8]N=[0x96][0xcd]'[0xd0]={[0x82]_[0xa5][0xe3][0xe4][0x1d]).[0xed][0xac][0xce]{[0xb6][0x8a][0xc][0x91]O[0xed]k[0xd2][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "[0x8][0xc3][0xd7]?T_[0xdb][0xd6]%[0x19][0xde]|[0xcf][0xee]?N[0x4][0xed][0x1f]L[0x16][0xff][0x16][0x91]o[0xe6][0x14][0xef][0x1f]h[0x96][0xe5]eV[0xe1][0x9a][0x98]k[0xe2][0x98][0x15][0x11][0xa8]T[0xb][0x0]|[0xfc][0xc6][0x9e]^[0x2][0x0][0x0][\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "0[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-2 << "[\r][\n]"
  > DEBUG: org.apache.http.headers - http-outgoing-2 << HTTP/1.1 200 OK
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Server: nginx
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Date: Sun, 17 Jul 2016 15:40:30 GMT
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Content-Type: application/json; charset=utf-8
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Transfer-Encoding: chunked
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Connection: keep-alive
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Vary: Accept-Encoding
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Vary: Accept-Encoding
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Strict-Transport-Security: max-age=15768000
  > DEBUG: org.apache.http.headers - http-outgoing-2 << Content-Encoding: gzip
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Connection can be kept alive indefinitely
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection [id: 2][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443] can be kept alive indefinitely
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection released: [id: 2][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 1; route allocated: 1 of 5; total allocated: 1 of 10]
  > DEBUG: org.mitre.openid.connect.client.OIDCAuthenticationFilter - from TokenEndpoint jsonString = {"access_token":"fec14841839e3ffd4ad48810b9d336d7f652b158fc39259ace3cea800b031b20","token_type":"Bearer","expires_in":1200,"id_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNzg1MjM1YzVhNjBlOGIwNjY3YzQzNjIwMDIwOWZjNGFlMDA3ZDllODdkYzgyYTZjMzc4NmMwZDM4ZWZkOTZhN3YxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2ODc3MTIzMCwiaWF0IjoxNDY4NzcwMDMwLCJub25jZSI6IjM4NzMzNjAzNmQ4ZTAiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.qNmrhh2MTDLv6u-gM3XxZiWXo6B_OQ6jJ6xEam4AjXQ"}

Tous les tokens sont renvoyés par le token endpoint car on a demandé initialement le scénario "authorization code flow".

ToDoList : Vérifier la présence de Cache-Control: no-store et Pragma: no-cache
ToDoList : Vérifier qu'en cas d'erreur, on reçoit bien { "error": "invalid_request" }

Le token endpoint a renvoyé l'access token et l'id token de type bearer, mais pas de refresh token :
  {
    "access_token":"fec14841839e3ffd4ad48810b9d336d7f652b158fc39259ace3cea800b031b20",
    "token_type":"Bearer",
    "expires_in":1200,
    "id_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNzg1MjM1YzVhNjBlOGIwNjY3YzQzNjIwMDIwOWZjNGFlMDA3ZDllODdkYzgyYTZjMzc4NmMwZDM4ZWZkOTZhN3YxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2ODc3MTIzMCwiaWF0IjoxNDY4NzcwMDMwLCJub25jZSI6IjM4NzMzNjAzNmQ4ZTAiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.qNmrhh2MTDLv6u-gM3XxZiWXo6B_OQ6jJ6xEam4AjXQ"
  }

Avec https://jwt.io, on analyse le contenu et la signature de l'id token :
  - header :
    {
      "typ": "JWT",
      "alg": "HS256"
    }
  - payload data :
    {
      "iss": "https://fcp.integ01.dev-franceconnect.fr",
      "sub": "785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1",
Le subject représente de manière unique et pérenne l'utilisateur qui s'est authentifié.
      "aud": "9ebf1ad9084207c5e4939bcc6c758c80f260ee70177a424e94754becefcb457e",
L'audience est bien le client id fourni par France Connect au fournisseur de service.
      "exp": 1468771230,
      "iat": 1468770030,
      "nonce": "387336036d8e0",
      "idp": "FC",
      "acr": "eidas2",
      "amr": []
    }
  - signature :
    on vérifie la signature HMAC-SHA256 avec le secret constitué du CLIENT_SECRET

Remarque : l'id token ne contient pas le hash optionnel de l'access token, donc ce dernier n'est pas vérifié.

On va récupérer les infos utilisateur via le endpoint userinfo, en fournissant l'access token dans l'entête suivante :
  Authorization: Bearer fec14841839e3ffd4ad48810b9d336d7f652b158fc39259ace3cea800b031b20

  > DEBUG: org.springframework.security.authentication.ProviderManager - Authentication attempt using org.mitre.openid.connect.client.OIDCAuthenticationProvider
  > DEBUG: org.mitre.openid.connect.client.UserInfoFetcher$1 - Created GET request for "https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo"
  > DEBUG: org.mitre.openid.connect.client.UserInfoFetcher$1 - Setting request Accept header to [text/plain, application/json, application/*+json, */*]
  > DEBUG: org.apache.http.client.protocol.RequestAddCookies - CookieSpec selected: default
  > DEBUG: org.apache.http.client.protocol.RequestAuthCache - Auth cache not set in the context
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection request: [route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 0; route allocated: 0 of 5; total allocated: 0 of 10]
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection leased: [id: 3][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 0; route allocated: 1 of 5; total allocated: 1 of 10]
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Opening connection {s}->https://fcp.integ01.dev-franceconnect.fr:443
  > DEBUG: org.apache.http.impl.conn.DefaultHttpClientConnectionOperator - Connecting to fcp.integ01.dev-franceconnect.fr/194.2.208.245:443
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Connecting socket to fcp.integ01.dev-franceconnect.fr/194.2.208.245:443 with timeout 0
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Enabled protocols: [TLSv1, TLSv1.1, TLSv1.2]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Enabled cipher suites:[TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256, TLS_DHE_RSA_WITH_AES_128_CBC_SHA256, TLS_DHE_DSS_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA, TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDH_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_DSS_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA, SSL_RSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA, TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA, TLS_EMPTY_RENEGOTIATION_INFO_SCSV]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Starting handshake
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory - Secure session established
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  negotiated protocol: TLSv1.2
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  negotiated cipher suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  peer principal: CN=*.integ01.dev-franceconnect.fr, OU=Gandi Standard Wildcard SSL, OU=Domain Control Validated
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  peer alternative names: [*.integ01.dev-franceconnect.fr, integ01.dev-franceconnect.fr]
  > DEBUG: org.apache.http.conn.ssl.SSLConnectionSocketFactory -  issuer principal: CN=Gandi Standard SSL CA 2, O=Gandi, L=Paris, ST=Paris, C=FR
  > DEBUG: org.apache.http.impl.conn.DefaultHttpClientConnectionOperator - Connection established 192.168.100.101:21532<->194.2.208.245:443
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Executing request GET /api/v1/userinfo HTTP/1.1
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Proxy auth state: UNCHALLENGED
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> GET /api/v1/userinfo HTTP/1.1
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> Authorization: Bearer fec14841839e3ffd4ad48810b9d336d7f652b158fc39259ace3cea800b031b20
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> Accept: text/plain, application/json, application/*+json, */*
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> Host: fcp.integ01.dev-franceconnect.fr
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> Connection: Keep-Alive
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> User-Agent: Apache-HttpClient/4.5.2 (Java/1.8.0_77)
  > DEBUG: org.apache.http.headers - http-outgoing-3 >> Accept-Encoding: gzip,deflate
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "GET /api/v1/userinfo HTTP/1.1[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "Authorization: Bearer fec14841839e3ffd4ad48810b9d336d7f652b158fc39259ace3cea800b031b20[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "Accept: text/plain, application/json, application/*+json, */*[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "Host: fcp.integ01.dev-franceconnect.fr[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "Connection: Keep-Alive[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "User-Agent: Apache-HttpClient/4.5.2 (Java/1.8.0_77)[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "Accept-Encoding: gzip,deflate[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 >> "[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "HTTP/1.1 200 OK[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Server: nginx[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Date: Sun, 17 Jul 2016 15:40:30 GMT[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Content-Type: application/json; charset=utf-8[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Transfer-Encoding: chunked[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Connection: keep-alive[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Vary: Accept-Encoding[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Vary: Accept-Encoding[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Strict-Transport-Security: max-age=15768000[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "Content-Encoding: gzip[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "11c[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "[0x1f][0x8b][0x8][0x0][0x0][0x0][0x0][0x0][0x0][0x3]U[0x90][0xcb]n[0xc2]0[0x10]E%[0xf2][0x9a] [0xe7][0xe5][0x7][0xab].[0xda]J]T[0xea][0x1f][0xa0]a<[0x1]KN[0x82]l[0x83][0x8a][0x10][0xff][0xde]1-[0xad][0xba][0xf4][0x99]s[0xe7][0xe1][0xab]H[0xa7][0x9d][0xd8][0x8]m[0x86][0xb6][0x1b]p[0x0]%[0xc9][0xec][0xa4]R[0x1a][0xfb]N[0xb5]R[0xb6][0xd2][0x8e][0xd8][0x3]I[0xa9][0x9d]%[0xa3][0x1d][0x9a][0x16][0x14]v[0xda]([0x94][0xae]34:[0xab]@[0x9f][0x1b][0xb1][0x12]{[0x9a][0x1d]E[0xee]6A ~[0xef]|[0xcc][0x7][0x7][0x99][0x18]5[0xd6]4[0xb5][0xec][0xeb][0xb6][0x88][0xf7][0x2].[0xa7]9[0xc7][0xb][0xd7][0xac]m[0xa4]|[0xe0]c[0x0],[0x81][0xde][0xf2][0xc8][0xd2][0xd4][0x9f]i[0xde][0xce]0[0x15][0xf8][0x12]=2[0x1b]a[0xf2][0xe1][0xf2][0x80][0xef][0x14][0xd1][0xf3][0xdc][0x95][0xa0][0x9]|`B[0xac][0xad][0xa7]o[0xfc]4F[0x98][0x91][0xd6]c[0x11][0xc0][0xb9]H)[0x89][0xcd]U[0x8c]K[0x9c] gr[0xec][0xb7][0xaa][0x8a]'[0xaa][0x9e])[0x81][0xff]\Uz[0x90][0xcd]P}@[0xf4][0x89]3)G[0xa2][0xbc][0xfd][0x8d][0xfe][0xb7]Y[0x8][0xb]B[0xf0][0xb9]\[0xf2][0xc8]D[0xda][0xfb]ef[0xf0][0x16][0xa8]vT[0xbf][0xde]w[0xe0][0xc2]qI[0x19][0xc2][0x16][0x17]W6[0xbf][0xf]b[0xfa][0xf7][0x15]?[0xe2][0xed][0xf6][0x5][0x90][0xfa]7[0xc1][0x99][0x1][0x0][0x0][\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "0[\r][\n]"
  > DEBUG: org.apache.http.wire - http-outgoing-3 << "[\r][\n]"
  > DEBUG: org.apache.http.headers - http-outgoing-3 << HTTP/1.1 200 OK
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Server: nginx
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Date: Sun, 17 Jul 2016 15:40:30 GMT
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Content-Type: application/json; charset=utf-8
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Transfer-Encoding: chunked
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Connection: keep-alive
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Vary: Accept-Encoding
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Vary: Accept-Encoding
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Strict-Transport-Security: max-age=15768000
  > DEBUG: org.apache.http.headers - http-outgoing-3 << Content-Encoding: gzip
  > DEBUG: org.apache.http.impl.execchain.MainClientExec - Connection can be kept alive indefinitely
  > DEBUG: org.mitre.openid.connect.client.UserInfoFetcher$1 - GET request for "https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo" resulted in 200 (OK)
  > DEBUG: org.mitre.openid.connect.client.UserInfoFetcher$1 - Reading [java.lang.String] as "application/json;charset=utf-8" using [org.springframework.http.converter.StringHttpMessageConverter@65d9f903]
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection [id: 3][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443] can be kept alive indefinitely
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection released: [id: 3][route: {s}->https://fcp.integ01.dev-franceconnect.fr:443][total kept alive: 1; route allocated: 1 of 5; total allocated: 1 of 10]

Les user info récupérées sont encodées en GZIP dans les traces JEE précédentes : [0x1f][0x8b][0x8][0x0][0x0][0x0][0x0][0x0][0x0][0x3]U[0x90][0xcb]n[0xc2]0[0x10]E%[0xf2][0x9a] [0xe7][0xe5][0x7][0xab].[0xda]J]T[0xea][0x1f][0xa0]a<[0x1]KN[0x82]l[0x83][0x8a][0x10][0xff][0xde]1-[0xad][0xba][0xf4][0x99]s[0xe7][0xe1][0xab]H[0xa7][0x9d][0xd8][0x8]m[0x86][0xb6][0x1b]p[0x0]%[0xc9][0xec][0xa4]R[0x1a][0xfb]N[0xb5]R[0xb6][0xd2][0x8e][0xd8][0x3]I[0xa9][0x9d]%[0xa3][0x1d][0x9a][0x16][0x14]v[0xda]([0x94][0xae]34:[0xab]@[0x9f][0x1b][0xb1][0x12]{[0x9a][0x1d]E[0xee]6A ~[0xef]|[0xcc][0x7][0x7][0x99][0x18]5[0xd6]4[0xb5][0xec][0xeb][0xb6][0x88][0xf7][0x2].[0xa7]9[0xc7][0xb][0xd7][0xac]m[0xa4]|[0xe0]c[0x0],[0x81][0xde][0xf2][0xc8][0xd2][0xd4][0x9f]i[0xde][0xce]0[0x15][0xf8][0x12]=2[0x1b]a[0xf2][0xe1][0xf2][0x80][0xef][0x14][0xd1][0xf3][0xdc][0x95][0xa0][0x9]|`B[0xac][0xad][0xa7]o[0xfc]4F[0x98][0x91][0xd6]c[0x11][0xc0][0xb9]H)[0x89][0xcd]U[0x8c]K[0x9c] gr[0xec][0xb7][0xaa][0x8a]'[0xaa][0x9e])[0x81][0xff]\Uz[0x90][0xcd]P}@[0xf4][0x89]3)G[0xa2][0xbc][0xfd][0x8d][0xfe][0xb7]Y[0x8][0xb]B[0xf0][0xb9]\[0xf2][0xc8]D[0xda][0xfb]ef[0xf0][0x16][0xa8]vT[0xbf][0xde]w[0xe0][0xc2]qI[0x19][0xc2][0x16][0x17]W6[0xbf][0xf]b[0xfa][0xf7][0x15]?[0xe2][0xed][0xf6][0x5][0x90][0xfa]7[0xc1][0x99][0x1][0x0][0x0][\r][\n]

Pour les récupérer dézippées, on rappelle avec curl l'URL userinfo avec l'access token fourni précédemment :
curl -vvvv -H 'Authorization: Bearer 9a7c142130aa9429d5c608b5054e0860a4be08c271e46b6b3f90cfdf6230cbba' https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo
  {
    "sub":"785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1",
    "gender":"male",
    "birthdate":"1981-04-21",
    "birthcountry":"99100",
    "birthplace":"49007",
    "given_name":"Eric",
    "family_name":"Mercier",
    "email":"eric.mercier@france.fr",
    "address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}
  }

Le security context est mis à jour par MitreID Connect et contient :
  - le principal :
    - le subject (l'identifiant unique de l'utilisateur)
    - l'issuer (France Connect)
  - le rôle affecté : ROLE_USER

  > DEBUG: org.mitre.openid.connect.client.OIDCAuthenticationFilter - Authentication success. Updating SecurityContextHolder to contain: org.mitre.openid.connect.model.OIDCAuthenticationToken@164e073d: Principal: {sub=785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1, iss=https://fcp.integ01.dev-franceconnect.fr}; Credentials: [PROTECTED]; Authenticated: true; Details: null; Granted Authorities: ROLE_USER, OIDC_785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1_https://fcp.integ01.dev-franceconnect.fr
  > DEBUG: org.springframework.security.web.authentication.SavedRequestAwareAuthenticationSuccessHandler - Redirecting to DefaultSavedRequest Url: http://127.0.0.1/user
  > DEBUG: org.springframework.security.web.DefaultRedirectStrategy - Redirecting to 'http://127.0.0.1/user'
  > DEBUG: org.springframework.security.web.context.HttpSessionSecurityContextRepository - SecurityContext 'org.springframework.security.core.context.SecurityContextImpl@164e073d: Authentication: org.mitre.openid.connect.model.OIDCAuthenticationToken@164e073d: Principal: {sub=785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1, iss=https://fcp.integ01.dev-franceconnect.fr}; Credentials: [PROTECTED]; Authenticated: true; Details: null; Granted Authorities: ROLE_USER, OIDC_785235c5a60e8b0667c436200209fc4ae007d9e87dc82a6c3786c0d38efd96a7v1_https://fcp.integ01.dev-franceconnect.fr' stored to HttpSession: 'org.apache.catalina.session.StandardSessionFacade@636c720c
  > DEBUG: org.springframework.security.web.context.SecurityContextPersistenceFilter - SecurityContextHolder now cleared, as request processing completed
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection manager is shutting down
  > DEBUG: org.apache.http.impl.conn.DefaultManagedHttpClientConnection - http-outgoing-2: Close connection
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection manager shut down
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection manager is shutting down
  > DEBUG: org.apache.http.impl.conn.DefaultManagedHttpClientConnection - http-outgoing-3: Close connection
  > DEBUG: org.apache.http.impl.conn.PoolingHttpClientConnectionManager - Connection manager shut down
