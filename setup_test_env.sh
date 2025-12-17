#!/bin/bash
# Setup script for AWS SSO test environment
# This script helps prepare the test environment

set -e

echo "=== AWS SSO Test Environment Setup ==="
echo

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Python
if command_exists python3; then
    echo "✓ Python 3 is installed: $(python3 --version)"
else
    echo "✗ Python 3 is not installed. Please install Python 3.6 or later."
    exit 1
fi

# Check AWS CLI
if command_exists aws; then
    echo "✓ AWS CLI is installed: $(aws --version)"
else
    echo "⚠ AWS CLI is not installed. Installing..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp/
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
    echo "✓ AWS CLI installed"
fi

# Check jq
if command_exists jq; then
    echo "✓ jq is installed"
else
    echo "⚠ jq is not installed. Attempting to install..."
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command_exists yum; then
        sudo yum install -y jq
    elif command_exists brew; then
        brew install jq
    else
        echo "✗ Could not install jq automatically. Please install it manually."
        exit 1
    fi
    echo "✓ jq installed"
fi

# Check aws-sso-util
if command_exists aws-sso-util; then
    echo "✓ aws-sso-util is installed: $(aws-sso-util --version 2>&1 || echo 'version unknown')"
else
    echo "⚠ aws-sso-util is not installed. Installing..."
    pip3 install aws-sso-util
    echo "✓ aws-sso-util installed"
fi

# Create test directories
echo
echo "Creating test directories..."
mkdir -p /tmp/app/output
echo "✓ Created /tmp/app/output"

# Copy example files if they exist
if [ -f "examples/profiles_identity.json" ]; then
    cp examples/profiles_identity.json /tmp/app/output/
    echo "✓ Copied example profiles_identity.json"
fi

# Copy hello file from repository-specific location or create a default one
if [ -f "git_task/hello world" ]; then
    cp "git_task/hello world" /tmp/app/
    echo "✓ Copied hello world file from git_task directory"
elif [ ! -f "/tmp/app/hello.txt" ]; then
    echo "hello world" > /tmp/app/hello.txt
    echo "✓ Created default hello.txt"
fi

echo
echo "=== Setup Complete ==="
echo
echo "Next steps:"
echo "1. Configure AWS SSO profiles in ~/.aws/config"
echo "2. Login using: aws-sso-util login --profile <profile-name>"
echo "3. Create /tmp/app/output/profiles_identity.json with your profile info"
echo "4. Run tests: python3 tests/test_aws_sso.py"
echo
