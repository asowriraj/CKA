#!/bin/bash
# Create mock TLS certificate for Gateway API practice

echo "Generating self-signed certificate for gateway.web.k8s.local..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Create OpenSSL config
cat > openssl.conf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = gateway.web.k8s.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = gateway.web.k8s.local
EOF

# Generate private key and self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key -out tls.crt -config openssl.conf 2>/dev/null

# Create Kubernetes secret
kubectl create secret tls web-cert \
    --key=tls.key --cert=tls.crt \
    --dry-run=client -o yaml | kubectl apply -f -

# Cleanup
cd -
rm -rf "$TEMP_DIR"

echo "✅ TLS secret 'web-cert' created"
