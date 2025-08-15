#!/bin/bash

echo "🔐 P12 Certificate Recreation Helper"
echo "====================================="
echo ""
echo "The GitHub Actions workflow failed to import your P12 certificate because"
echo "none of the attempted passwords worked. Let's fix this!"
echo ""

echo "📋 You have two options:"
echo ""
echo "1️⃣  Recreate P12 WITHOUT password (Recommended)"
echo "2️⃣  Recreate P12 WITH a known password"
echo ""

read -p "Choose option (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo "✅ Option 1: Creating P12 WITHOUT password"
        echo ""
        echo "Run this command on your Mac:"
        echo ""
        echo "openssl pkcs12 -export -out ios_distribution.p12 -inkey ios_distribution.key -in ios_distribution.cer -nodes"
        echo ""
        echo "Then:"
        echo "1. Convert to base64: base64 -w 0 ios_distribution.p12 > ios_cert_base64.txt"
        echo "2. Update GitHub secret 'IOS_DIST_CERTIFICATE' with the content of ios_cert_base64.txt"
        echo "3. Delete or clear the 'IOS_DIST_CERTIFICATE_PASSWORD' secret"
        echo ""
        ;;
    2)
        echo ""
        echo "✅ Option 2: Creating P12 WITH password"
        echo ""
        read -p "Enter the password you want to use: " password
        echo ""
        echo "Run this command on your Mac:"
        echo ""
        echo "openssl pkcs12 -export -out ios_distribution.p12 -inkey ios_distribution.key -in ios_distribution.cer -passout pass:$password"
        echo ""
        echo "Then:"
        echo "1. Convert to base64: base64 -w 0 ios_distribution.p12 > ios_cert_base64.txt"
        echo "2. Update GitHub secret 'IOS_DIST_CERTIFICATE' with the content of ios_cert_base64.txt"
        echo "3. Update GitHub secret 'IOS_DIST_CERTIFICATE_PASSWORD' with: $password"
        echo ""
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and choose 1 or 2."
        exit 1
        ;;
esac

echo "🎯 After updating the GitHub secrets, create a new tag to trigger the workflow:"
echo ""
echo "git tag release-v1.0.8"
echo "git push origin release-v1.0.8"
echo ""
echo "✅ This should resolve the certificate import issue!"
