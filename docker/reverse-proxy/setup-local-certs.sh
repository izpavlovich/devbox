#!/bin/bash
# Setup local HTTPS certificates using mkcert

set -e

echo "Setting up local HTTPS certificates with mkcert..."

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "mkcert is not installed. Installing..."

    # Detect OS and install
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install mkcert
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get update
        sudo apt-get install -y libnss3-tools
        curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
        chmod +x mkcert-v*-linux-amd64
        sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    else
        echo "Unsupported OS. Please install mkcert manually: https://github.com/FiloSottile/mkcert"
        exit 1
    fi
fi

# Install local CA
echo "Installing local Certificate Authority..."
mkcert -install

# Create certs directory
mkdir -p certs

# Generate wildcard certificate for *.localhost
echo "Generating wildcard certificate for *.localhost..."
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem "*.localhost" "*.*.localhost" localhost 127.0.0.1 ::1

echo "✓ Certificates created successfully!"
echo "  - Certificate: certs/local-cert.pem"
echo "  - Key: certs/local-key.pem"
echo ""
echo "Next steps:"
echo "  1. Update docker-compose.yml to use the certificates"
echo "  2. Restart Traefik: docker compose down && docker compose up -d"
