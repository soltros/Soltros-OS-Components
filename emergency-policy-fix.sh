#!/bin/bash

# Soltros OS - Emergency Policy.json Fix Script
# This script fixes container signature verification issues

set -e

echo "================================================"
echo "Soltros OS - Emergency Policy Fix"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Backup existing policy.json
POLICY_FILE="/etc/containers/policy.json"
BACKUP_FILE="/etc/containers/policy.json.backup.$(date +%Y%m%d_%H%M%S)"

if [ -f "$POLICY_FILE" ]; then
    echo "📋 Backing up existing policy.json to:"
    echo "   $BACKUP_FILE"
    cp "$POLICY_FILE" "$BACKUP_FILE"
    echo "✅ Backup created"
    echo ""
fi

# Create the new policy.json
echo "📝 Creating new policy.json configuration..."

cat > "$POLICY_FILE" << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "ghcr.io/soltros/soltros-os": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os_lts": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-lts_cosmic": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-unstable_cosmic": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os-lts_gnome": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os-unstable_gnome": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ]
        },
        "docker-daemon": {
            "": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        }
    }
}
EOF

echo "✅ New policy.json created"
echo ""

# Verify JSON syntax
echo "🔍 Verifying JSON syntax..."
if command -v jq &> /dev/null; then
    if jq . "$POLICY_FILE" > /dev/null 2>&1; then
        echo "✅ JSON syntax is valid"
    else
        echo "❌ ERROR: JSON syntax is invalid"
        echo "   Restoring backup..."
        cp "$BACKUP_FILE" "$POLICY_FILE"
        exit 1
    fi
else
    echo "⚠️  Warning: jq not installed, skipping JSON validation"
fi

echo ""

# Check for public key
PUB_KEY="/etc/pki/containers/soltros.pub"
if [ -f "$PUB_KEY" ]; then
    echo "✅ Soltros public key found at $PUB_KEY"
else
    echo "⚠️  Warning: Public key not found at $PUB_KEY"
    echo "   Signature verification may fail for Soltros images"
fi

echo ""
echo "================================================"
echo "✅ Policy fix completed successfully!"
echo "================================================"
echo ""
echo "What was fixed:"
echo "  • Added signature verification for all Soltros OS variants"
echo "  • Ensured Distrobox and other containers work without issues"
echo "  • Backup saved to: $BACKUP_FILE"
echo ""
echo "You can now run rpm-ostree commands normally."
echo ""

exit 0