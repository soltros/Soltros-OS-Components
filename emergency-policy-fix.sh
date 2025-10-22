#!/bin/bash

# Soltros OS - Emergency Update & Policy Fix Script
# This script temporarily bypasses signature verification, updates the system,
# then installs the correct signed policy for future updates.

set -e

echo "================================================"
echo "Soltros OS - Emergency Update & Policy Fix"
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

# Step 1: Install temporary permissive policy
echo "📝 Step 1: Installing temporary permissive policy..."
cat > "$POLICY_FILE" << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "ghcr.io/soltros": [
                {
                    "type": "insecureAcceptAnything"
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

echo "✅ Temporary policy installed"
echo ""

# Step 2: Run bootc upgrade
echo "🔄 Step 2: Running system update..."
echo "This may take several minutes..."
echo ""

if bootc upgrade; then
    echo ""
    echo "✅ System update completed successfully!"
    echo ""
else
    echo ""
    echo "❌ ERROR: System update failed"
    echo "   Restoring original policy..."
    cp "$BACKUP_FILE" "$POLICY_FILE"
    exit 1
fi

# Step 3: Install proper signed policy
echo "📝 Step 3: Installing proper signature verification policy..."
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

echo "✅ Proper policy installed"
echo ""

# Verify JSON syntax
echo "🔍 Verifying policy configuration..."
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
    echo "   This should be included in the updated image"
fi

echo ""
echo "================================================"
echo "✅ Update and policy fix completed successfully!"
echo "================================================"
echo ""
echo "What was done:"
echo "  1. Temporarily bypassed signature verification"
echo "  2. Updated system to latest signed image"
echo "  3. Installed proper signature verification policy"
echo ""
echo "Next steps:"
echo "  • Reboot to boot into the new image"
echo "  • Future updates will use signature verification automatically"
echo "  • Backup saved to: $BACKUP_FILE"
echo ""
echo "Please reboot your system now: sudo reboot"
echo ""

exit 0