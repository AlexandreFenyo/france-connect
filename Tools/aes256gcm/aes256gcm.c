
/* (c) Alexandre Fenyo - 2017 */

// AES-256-GCM with libcrypto
// gcc -Wall -lcrypto -o aes256gcm aes256gcm.c

// tag is 16 bytes long
// no AAD (Additional Associated Data)
// output format: tag is written just after cipher text (see RFC-5116, sections 5.1 and 5.2)

// KEY=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
// IV=87b7225d16ea2ae1f41d0b13fdce9bba
// echo -n 'Texte en clair' | ./aes256gcm $KEY $IV | od -t x1

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>

EVP_CIPHER_CTX *ctx = NULL;
unsigned char *iv = NULL;
unsigned char *buf_plain = NULL;
unsigned char *buf_cipher = NULL;

typedef enum { false, true } bool;

void freeCrypto() {
  if (ctx) {
    EVP_CIPHER_CTX_free(ctx);
    ctx = NULL;
  }
  CRYPTO_cleanup_all_ex_data();
  ERR_free_strings();

  if (iv) {
    free(iv);
    iv = NULL;
  }
  if (buf_plain) {
    free(buf_plain);
    buf_plain = NULL;
  }
  if (buf_cipher) {
    free(buf_cipher);
    buf_cipher = NULL;
  }
}

void handleCryptoError() {
  fprintf(stderr, "ERROR\n");
  ERR_print_errors_fp(stderr);
  freeCrypto();
  exit(1);
}

bool isValidHexChar(char c) {
  return (c >= 'a' && c <= 'f') || (c >= '0' && c <= '9');
}

unsigned char hex2uchar(char *hex) {
  unsigned char ret;

  if (hex[0] >= 'a' && hex[0] <= 'f') ret = (hex[0] - 'a' + 10) * 16;
  else ret = (hex[0] - '0') * 16;
  if (hex[1] >= 'a' && hex[1] <= 'f') ret += hex[1] - 'a' + 10;
  else ret += hex[1] - '0';
  return ret;
}

int main(int ac, char **av, char **ae)
{
  const EVP_CIPHER *cipher;
  unsigned char key[32];
  int iv_len, len, i;
  unsigned char tag[16];

  if (ac != 3) {
    fprintf(stderr, "usage: %s KEY IV\n", av[0]);
    return 1;
  }

  char *key_txt = av[1];
  char *iv_txt = av[2];

  ERR_load_crypto_strings();

  if (strlen(key_txt) != 2 * sizeof key) {
    fprintf(stderr, "invalid key size\n");
    freeCrypto();
    return 1;
  }

  if (strlen(iv_txt) < 2 || strlen(iv_txt) % 2) {
    fprintf(stderr, "invalid IV size\n");
    freeCrypto();
    return 1;
  }
  iv_len = strlen(iv_txt) / 2;

  if (!(iv = malloc(iv_len))) {
    perror("malloc");
    freeCrypto();
    return 1;
  }

  if (!(buf_plain = malloc(iv_len))) {
    perror("malloc");
    freeCrypto();
    return 1;
  }

  if (!(buf_cipher = malloc(iv_len))) {
    perror("malloc");
    freeCrypto();
    return 1;
  }

  for (i = 0; i < sizeof key; i++) {
    if (!isValidHexChar(key_txt[2*i]) || !isValidHexChar(key_txt[2*i+1])) handleCryptoError();
    key[i] = hex2uchar(key_txt + 2*i);
  }

  for (i = 0; i < iv_len; i++) {
    if (!isValidHexChar(iv_txt[2*i]) || !isValidHexChar(iv_txt[2*i+1])) handleCryptoError();
    iv[i] = hex2uchar(iv_txt + 2*i);
  }

  if (!(ctx = EVP_CIPHER_CTX_new())) handleCryptoError();
  if (!(cipher = EVP_aes_256_gcm())) handleCryptoError();
  if (1 != EVP_EncryptInit_ex(ctx, cipher, NULL, NULL, NULL)) handleCryptoError();
  if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL)) handleCryptoError();
  if (1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv)) handleCryptoError();

  do {
    size_t ret = fread(buf_plain, 1, iv_len, stdin);
    if (!ret) {
      if (ferror(stdin)) {
	perror("fread");
        freeCrypto();
        return 1;
      }
      if (feof(stdin)) break;
    }

    if (1 != EVP_EncryptUpdate(ctx, buf_cipher, &len, buf_plain, ret)) handleCryptoError();

    if (len && !fwrite(buf_cipher, len, 1, stdout)) {
      if (feof(stderr)) fprintf(stderr, "EOF on output stream\n");
      else perror("fwrite");
      freeCrypto();
      return 1;
    }

  } while (1);

  if (1 != EVP_EncryptFinal_ex(ctx, buf_cipher, &len)) handleCryptoError();

  if (len && !fwrite(buf_cipher, len, 1, stdout)) {
    if (feof(stderr)) fprintf(stderr, "EOF on output stream\n");
    else perror("fwrite");
    freeCrypto();
    return 1;
  }

  if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, sizeof tag, tag)) handleCryptoError();
  if (!fwrite(tag, sizeof tag, 1, stdout)) {
    if (feof(stderr)) fprintf(stderr, "EOF on output stream\n");
    else perror("fwrite");
    freeCrypto();
    return 1;
  }

  fflush(stdout);
  freeCrypto();
  return 0;
}
