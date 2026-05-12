#!/bin/sh
# Generates self-signed TLS certificates for MongoDB x509 authentication.
# Run this once before `docker compose up`.
# Certs are written to deadline/certs/ (gitignored).
set -e

CERT_DIR="$(dirname "$0")/../certs"
mkdir -p "$CERT_DIR"

SUBJECT_BASE="/O=Thinkbox/OU=Deadline"
CA_SUBJ="$SUBJECT_BASE/CN=DeadlineCA"
SERVER_SUBJ="$SUBJECT_BASE/CN=deadline_db"
CLIENT_SUBJ="$SUBJECT_BASE/CN=deadline-client"

echo "Generating CA key and certificate..."
openssl genrsa -out "$CERT_DIR/ca.key" 4096
openssl req -new -x509 -days 3650 -key "$CERT_DIR/ca.key" \
  -subj "$CA_SUBJ" \
  -out "$CERT_DIR/ca.crt"

echo "Generating MongoDB server key and certificate..."
openssl genrsa -out "$CERT_DIR/server.key" 4096
openssl req -new -key "$CERT_DIR/server.key" \
  -subj "$SERVER_SUBJ" \
  -out "$CERT_DIR/server.csr"
openssl x509 -req -days 3650 \
  -in "$CERT_DIR/server.csr" \
  -CA "$CERT_DIR/ca.crt" \
  -CAkey "$CERT_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERT_DIR/server.crt"
# MongoDB requires cert + key concatenated in a single PEM file
cat "$CERT_DIR/server.crt" "$CERT_DIR/server.key" > "$CERT_DIR/server.pem"

echo "Generating Deadline client key and certificate..."
openssl genrsa -out "$CERT_DIR/client.key" 4096
openssl req -new -key "$CERT_DIR/client.key" \
  -subj "$CLIENT_SUBJ" \
  -out "$CERT_DIR/client.csr"
openssl x509 -req -days 3650 \
  -in "$CERT_DIR/client.csr" \
  -CA "$CERT_DIR/ca.crt" \
  -CAkey "$CERT_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERT_DIR/client.crt"
# Deadline also requires cert + key concatenated (used for MongoDB TLS verification)
cat "$CERT_DIR/client.crt" "$CERT_DIR/client.key" > "$CERT_DIR/client.pem"

# Deadline's Mono runtime requires a PKCS#12 (.pfx) file for the client certificate.
# Using an empty passphrase so no --dbcertpass flag is needed.
echo "Converting client cert to PKCS#12 format for Deadline..."
openssl pkcs12 -export \
  -in "$CERT_DIR/client.crt" \
  -inkey "$CERT_DIR/client.key" \
  -out "$CERT_DIR/client.pfx" \
  -passout pass:

echo ""
echo "Certificates generated in $CERT_DIR"
echo ""
echo "MongoDB x509 username (used to create the DB user):"
openssl x509 -in "$CERT_DIR/client.crt" -noout -subject -nameopt RFC2253 | sed 's/^subject=//'
