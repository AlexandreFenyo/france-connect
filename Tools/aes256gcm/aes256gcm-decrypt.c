
/* (c) Alexandre Fenyo - 2017 */

// AES-256-GCM with libcrypto
// gcc -Wall -lcrypto -o aes256gcm-decrypt aes256gcm-decrypt.c

// tag is 16 bytes long
// no AAD (Additional Associated Data)
// input format: tag is read just after cipher text (see RFC-5116, sections 5.1 and 5.2)

// KEY=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
// IV=87b7225d16ea2ae1f41d0b13fdce9bba
// cat ciphertext | ./aes256gcm-decrypt $KEY $IV

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
unsigned char *input = NULL;

typedef enum { false, true } bool;

void freeCrypto() {
  if (input) free(input);

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

unsigned char *loadInput(int *plen) {
  int len = 0;
  unsigned char *buf = NULL;
  unsigned char *old_buf;

  do {
    int c = fgetc(stdin);
    if (c == EOF) break;
    if (c < 0) {
      perror("fgetc");
      exit(1);
    }
    len++;
    old_buf = buf;
    buf = malloc(len);
    if (buf < 0) {
      perror("malloc");
      exit(1);
    }
    if (len > 1) bcopy(old_buf, buf, len - 1);
    buf[len - 1] = c;
    if (old_buf) free(old_buf);
  } while (1);

  *plen = len;
  return buf;
}

int main(int ac, char **av, char **ae)
{
  const EVP_CIPHER *cipher;
  unsigned char key[32];
  int iv_len, len, i;
  unsigned char *current;
  int input_len;

  if (ac != 3) {
    fprintf(stderr, "usage: %s KEY IV\n", av[0]);
    return 1;
  }

  char *key_txt = av[1];
  char *iv_txt = av[2];

  input = loadInput(&input_len);
  current = input;

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
  if (1 != EVP_DecryptInit_ex(ctx, cipher, NULL, NULL, NULL)) handleCryptoError();
  if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL)) handleCryptoError();
  if (1 != EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv)) handleCryptoError();
  if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, input + input_len - 16)) handleCryptoError();

  do {
    int nbytes = input + input_len - 16 - current;
    if (nbytes > iv_len) nbytes = iv_len;
    if (!nbytes) break;

    bcopy(current, buf_plain, nbytes);
    current += nbytes;

    if (1 != EVP_DecryptUpdate(ctx, buf_cipher, &len, buf_plain, nbytes)) handleCryptoError();

    if (len && !fwrite(buf_cipher, len, 1, stdout)) {
      if (feof(stderr)) fprintf(stderr, "EOF on output stream\n");
      else perror("fwrite");
      freeCrypto();
      return 1;
    }

  } while (1);

  // correct tag is checked here
  if (EVP_DecryptFinal_ex(ctx, buf_cipher, &len) <= 0) handleCryptoError();

  if (len && !fwrite(buf_cipher, len, 1, stdout)) {
    if (feof(stderr)) fprintf(stderr, "EOF on output stream\n");
    else perror("fwrite");
    freeCrypto();
    return 1;
  }

  fflush(stdout);
  freeCrypto();
  return 0;
}
