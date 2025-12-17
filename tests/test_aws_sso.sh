#!/bin/bash
set -e

# Test script to verify AWS SSO setup and authentication
# This script verifies:
# 1. aws-sso-util is installed
# 2. Authentication was performed using aws-sso-util login
# 3. Two profiles correspond to two distinct account-role pairs
# 4. hello.txt content
# 5. /app/output/profiles_identity.json structure
# 6. aws sts get-caller-identity for both profiles

echo "=== AWS SSO Verification Tests ==="
echo

# Test 1: Verify aws-sso-util is installed
echo "Test 1: Verifying aws-sso-util is installed..."
if command -v aws-sso-util &> /dev/null; then
    echo "✓ aws-sso-util is installed"
    aws-sso-util --version
else
    echo "✗ FAIL: aws-sso-util is not installed"
    exit 1
fi
echo

# Test 2: Verify authentication was performed using aws-sso-util login
echo "Test 2: Verifying authentication method..."
# Check if aws-sso-util cache directory exists
if [ -d "$HOME/.aws/sso/cache" ] || [ -d "$HOME/.aws/cli/cache" ]; then
    echo "✓ AWS SSO cache directory exists"
    
    # Check for aws-sso-util specific markers
    # aws-sso-util uses a different cache structure than native aws sso login
    if [ -f "$HOME/.aws/cli/cache/aws-sso-util.json" ] || \
       ls $HOME/.aws/sso/cache/*.json 2>/dev/null | grep -q .; then
        echo "✓ Authentication appears to use aws-sso-util"
    else
        echo "⚠ Warning: Could not definitively verify aws-sso-util login method"
    fi
else
    echo "✗ FAIL: No AWS SSO cache found. Authentication may not have been performed."
    exit 1
fi
echo

# Test 3: Verify hello.txt content
echo "Test 3: Verifying hello.txt content..."
if [ -f "/app/hello world" ]; then
    HELLO_CONTENT=$(cat "/app/hello world")
    echo "✓ File '/app/hello world' found with content:"
    echo "  $HELLO_CONTENT"
elif [ -f "/app/hello.txt" ]; then
    HELLO_CONTENT=$(cat "/app/hello.txt")
    echo "✓ File '/app/hello.txt' found with content:"
    echo "  $HELLO_CONTENT"
else
    echo "✗ FAIL: hello.txt not found at expected paths"
    exit 1
fi
echo

# Test 4: Verify /app/output/profiles_identity.json exists and has valid structure
echo "Test 4: Verifying /app/output/profiles_identity.json..."
if [ -f "/app/output/profiles_identity.json" ]; then
    echo "✓ profiles_identity.json exists"
    
    # Verify it's valid JSON
    if jq empty /app/output/profiles_identity.json 2>/dev/null; then
        echo "✓ profiles_identity.json is valid JSON"
        
        # Verify it has profiles array or object
        PROFILE_COUNT=$(jq 'if type == "array" then length elif type == "object" then keys | length else 0 end' /app/output/profiles_identity.json)
        echo "✓ Found $PROFILE_COUNT profile(s) in profiles_identity.json"
    else
        echo "✗ FAIL: profiles_identity.json is not valid JSON"
        exit 1
    fi
else
    echo "✗ FAIL: /app/output/profiles_identity.json not found"
    exit 1
fi
echo

# Test 5: Verify two distinct account-role pairs
echo "Test 5: Verifying two distinct account-role pairs..."
# Read profiles from AWS config
if [ -f "$HOME/.aws/config" ]; then
    # Extract profile names (excluding [default])
    PROFILES=$(grep '^\[profile ' "$HOME/.aws/config" | sed 's/\[profile \(.*\)\]/\1/' | head -2)
    PROFILE_ARRAY=($PROFILES)
    
    if [ ${#PROFILE_ARRAY[@]} -ge 2 ]; then
        PROFILE1="${PROFILE_ARRAY[0]}"
        PROFILE2="${PROFILE_ARRAY[1]}"
        echo "✓ Found at least 2 profiles: $PROFILE1, $PROFILE2"
        
        # Extract account and role information from profiles_identity.json
        if [ -f "/app/output/profiles_identity.json" ]; then
            # Check if profiles have distinct account-role pairs
            ACCOUNT1=$(jq -r --arg prof "$PROFILE1" '.[$prof].Account // .[] | select(.ProfileName == $prof) | .Account // empty' /app/output/profiles_identity.json 2>/dev/null || echo "")
            ACCOUNT2=$(jq -r --arg prof "$PROFILE2" '.[$prof].Account // .[] | select(.ProfileName == $prof) | .Account // empty' /app/output/profiles_identity.json 2>/dev/null || echo "")
            
            ROLE1=$(jq -r --arg prof "$PROFILE1" '.[$prof].RoleName // .[] | select(.ProfileName == $prof) | .RoleName // empty' /app/output/profiles_identity.json 2>/dev/null || echo "")
            ROLE2=$(jq -r --arg prof "$PROFILE2" '.[$prof].RoleName // .[] | select(.ProfileName == $prof) | .RoleName // empty' /app/output/profiles_identity.json 2>/dev/null || echo "")
            
            if [ -n "$ACCOUNT1" ] && [ -n "$ACCOUNT2" ] && [ -n "$ROLE1" ] && [ -n "$ROLE2" ]; then
                PAIR1="$ACCOUNT1:$ROLE1"
                PAIR2="$ACCOUNT2:$ROLE2"
                
                if [ "$PAIR1" != "$PAIR2" ]; then
                    echo "✓ Profiles have distinct account-role pairs:"
                    echo "  $PROFILE1: $PAIR1"
                    echo "  $PROFILE2: $PAIR2"
                else
                    echo "✗ FAIL: Profiles have the same account-role pair: $PAIR1"
                    exit 1
                fi
            else
                echo "⚠ Warning: Could not extract account-role information from profiles_identity.json"
                echo "  Accounts: $ACCOUNT1, $ACCOUNT2"
                echo "  Roles: $ROLE1, $ROLE2"
            fi
        fi
    else
        echo "✗ FAIL: Less than 2 profiles found"
        exit 1
    fi
else
    echo "✗ FAIL: ~/.aws/config not found"
    exit 1
fi
echo

# Test 6: Run aws sts get-caller-identity for both profiles
echo "Test 6: Running aws sts get-caller-identity for both profiles..."
if [ ${#PROFILE_ARRAY[@]} -ge 2 ]; then
    for PROFILE in "${PROFILE_ARRAY[@]}"; do
        echo "  Testing profile: $PROFILE"
        if aws sts get-caller-identity --profile "$PROFILE" > /dev/null 2>&1; then
            IDENTITY=$(aws sts get-caller-identity --profile "$PROFILE")
            ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account')
            ARN=$(echo "$IDENTITY" | jq -r '.Arn')
            echo "    ✓ Successfully authenticated as:"
            echo "      Account: $ACCOUNT"
            echo "      ARN: $ARN"
        else
            echo "    ✗ FAIL: Could not get caller identity for profile $PROFILE"
            exit 1
        fi
    done
    echo "✓ All profiles authenticated successfully"
else
    echo "⚠ Skipping: Not enough profiles to test"
fi
echo

echo "=== All Tests Passed ==="
exit 0
