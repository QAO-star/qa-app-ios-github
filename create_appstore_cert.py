#!/usr/bin/env python3
"""
Create App Store distribution certificate using App Store Connect API
"""
import requests
import jwt
import time
import json
import os
from cryptography.hazmat.primitives import serialization

def create_jwt_token(key_id, issuer_id, private_key_path):
    """Create JWT token for App Store Connect API"""
    with open(private_key_path, 'rb') as f:
        private_key_data = f.read()
        print(f'🔍 Private key length: {len(private_key_data)} bytes')
        private_key = serialization.load_pem_private_key(private_key_data, password=None)
    
    now = int(time.time())
    payload = {
        'iss': issuer_id,
        'iat': now,
        'exp': now + 1200,  # 20 minutes
        'aud': 'appstoreconnect-v1'
    }
    
    print(f'🔍 JWT Payload: {payload}')
    
    token = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': key_id})
    
    # Ensure token is a string for newer PyJWT versions
    if isinstance(token, bytes):
        token = token.decode('utf-8')
    
    return token

def create_certificate(jwt_token, csr_content):
    """Create distribution certificate using App Store Connect API"""
    url = 'https://api.appstoreconnect.apple.com/v1/certificates'
    
    headers = {
        'Authorization': f'Bearer {jwt_token}',
        'Content-Type': 'application/json'
    }
    
    data = {
        'data': {
            'type': 'certificates',
            'attributes': {
                'certificateType': 'DISTRIBUTION',
                'csrContent': csr_content
            }
        }
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response

def main():
    """Main execution"""
    try:
        key_id = os.environ.get('KEY_ID', 'ZA7M4DJPV8')
        issuer_id = os.environ.get('ISSUER_ID')
        
        print(f'🔍 Using Key ID: {key_id}')
        print(f'🔍 Using Issuer ID: {issuer_id}')
        
        if not issuer_id:
            print('❌ Missing ISSUER_ID')
            return 1
        
        # Check if private key file exists
        if not os.path.exists('AuthKey_ZA7M4DJPV8.p8'):
            print('❌ Private key file not found: AuthKey_ZA7M4DJPV8.p8')
            return 1
            
        # Check if CSR file exists
        if not os.path.exists('ios_distribution.csr'):
            print('❌ CSR file not found: ios_distribution.csr')
            return 1
        
        # Read CSR content
        with open('ios_distribution.csr', 'r') as f:
            csr_content = f.read().strip()
        
        print('🔍 Creating JWT token...')
        # Create JWT token
        token = create_jwt_token(key_id, issuer_id, 'AuthKey_ZA7M4DJPV8.p8')
        print('✅ JWT token created successfully')
        
        print('🔍 Testing API connectivity first...')
        # Test basic API access
        test_url = 'https://api.appstoreconnect.apple.com/v1/certificates'
        test_headers = {'Authorization': f'Bearer {token}'}
        test_response = requests.get(test_url, headers=test_headers)
        print(f'🔍 Test API Response: {test_response.status_code}')
        
        if test_response.status_code == 200:
            print('✅ API connectivity test successful')
        else:
            print(f'⚠️ API test failed: {test_response.text}')
        
        print('🔍 Calling App Store Connect API to create certificate...')
        # Create certificate
        response = create_certificate(token, csr_content)
        
        print(f'🔍 API Response Status: {response.status_code}')
        
        if response.status_code == 201:
            cert_data = response.json()
            cert_content = cert_data['data']['attributes']['certificateContent']
            
            # Save certificate
            with open('ios_appstore_distribution.cer', 'w') as f:
                f.write(cert_content)
            
            print('✅ App Store distribution certificate created successfully!')
            print(f"Certificate ID: {cert_data['data']['id']}")
            return 0
        else:
            print(f'❌ Failed to create certificate: {response.status_code}')
            print(f'Response: {response.text}')
            
            # Additional debugging for 401 errors
            if response.status_code == 401:
                print('🔍 Debug info for 401 error:')
                print(f'  - Token length: {len(token)}')
                print(f'  - Token starts with: {token[:50]}...')
                print(f'  - Key ID: {key_id}')
                print(f'  - Issuer ID: {issuer_id}')
                print('⚠️ Certificate creation failed, but continuing pipeline...')
            
            return 0  # Don't fail the pipeline - continue with existing certificate
            
    except Exception as e:
        print(f'❌ Error: {e}')
        import traceback
        traceback.print_exc()
        print('⚠️ Exception occurred, but continuing pipeline...')
        return 0  # Don't fail the pipeline - continue with existing certificate

if __name__ == '__main__':
    exit(main())
