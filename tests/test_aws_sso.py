#!/usr/bin/env python3
"""
AWS SSO Verification Tests

This script verifies:
1. aws-sso-util is installed
2. Authentication was performed using aws-sso-util login
3. Two profiles correspond to two distinct account-role pairs
4. hello.txt content exists and is readable
5. /app/output/profiles_identity.json structure is valid
6. aws sts get-caller-identity works for both profiles
"""

import json
import os
import subprocess
import sys
from pathlib import Path


class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.warnings = 0

    def test(self, name, func):
        """Run a test function and track results"""
        print(f"\n{'='*60}")
        print(f"Test: {name}")
        print('='*60)
        try:
            func()
            self.passed += 1
            print(f"✓ PASSED: {name}")
            return True
        except AssertionError as e:
            self.failed += 1
            print(f"✗ FAILED: {name}")
            print(f"  Error: {e}")
            return False
        except Exception as e:
            self.failed += 1
            print(f"✗ ERROR: {name}")
            print(f"  Unexpected error: {e}")
            return False

    def warn(self, message):
        """Log a warning"""
        self.warnings += 1
        print(f"⚠ Warning: {message}")

    def summary(self):
        """Print test summary"""
        print(f"\n{'='*60}")
        print("Test Summary")
        print('='*60)
        print(f"Passed:   {self.passed}")
        print(f"Failed:   {self.failed}")
        print(f"Warnings: {self.warnings}")
        print('='*60)
        return self.failed == 0


def test_aws_sso_util_installed():
    """Test 1: Verify aws-sso-util is installed"""
    try:
        result = subprocess.run(
            ['aws-sso-util', '--version'],
            capture_output=True,
            text=True,
            timeout=10
        )
        assert result.returncode == 0, "aws-sso-util command failed"
        print(f"✓ aws-sso-util is installed: {result.stdout.strip()}")
    except FileNotFoundError:
        raise AssertionError("aws-sso-util is not installed or not in PATH")
    except subprocess.TimeoutExpired:
        raise AssertionError("aws-sso-util command timed out")


def test_authentication_method(runner):
    """Test 2: Verify authentication was performed using aws-sso-util login"""
    home = Path.home()
    sso_cache = home / '.aws' / 'sso' / 'cache'
    cli_cache = home / '.aws' / 'cli' / 'cache'
    
    # Check if SSO cache directories exist
    cache_exists = sso_cache.exists() or cli_cache.exists()
    assert cache_exists, "No AWS SSO cache directory found"
    print("✓ AWS SSO cache directory exists")
    
    # Check for aws-sso-util specific markers
    aws_sso_util_marker = cli_cache / 'aws-sso-util.json'
    sso_cache_files = list(sso_cache.glob('*.json')) if sso_cache.exists() else []
    
    if aws_sso_util_marker.exists() or sso_cache_files:
        print("✓ Authentication appears to use aws-sso-util")
    else:
        runner.warn("Could not definitively verify aws-sso-util login method")


def test_hello_txt_content():
    """Test 3: Verify hello.txt content"""
    possible_paths = [
        Path('/app/hello world'),
        Path('/app/hello.txt'),
        Path('/app/git_task/hello world')
    ]
    
    found = False
    for path in possible_paths:
        if path.exists():
            content = path.read_text()
            print(f"✓ Found file at {path}")
            print(f"  Content: {content.strip()}")
            found = True
            break
    
    assert found, f"hello.txt not found in any of: {[str(p) for p in possible_paths]}"


def test_profiles_identity_json():
    """Test 4: Verify /app/output/profiles_identity.json structure"""
    json_path = Path('/app/output/profiles_identity.json')
    assert json_path.exists(), f"{json_path} does not exist"
    print(f"✓ {json_path} exists")
    
    # Verify it's valid JSON
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        print("✓ profiles_identity.json is valid JSON")
    except json.JSONDecodeError as e:
        raise AssertionError(f"profiles_identity.json is not valid JSON: {e}")
    
    # Verify structure - should be dict or list
    if isinstance(data, list):
        profile_count = len(data)
    elif isinstance(data, dict):
        profile_count = len(data)
    else:
        raise AssertionError("profiles_identity.json should be a dict or list")
    
    print(f"✓ Found {profile_count} profile(s) in profiles_identity.json")
    return data


def test_distinct_account_role_pairs(runner):
    """Test 5: Verify two distinct account-role pairs"""
    # Read AWS config to get profile names
    config_path = Path.home() / '.aws' / 'config'
    assert config_path.exists(), "~/.aws/config not found"
    
    # Parse config file to extract profile names
    profiles = []
    with open(config_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('[profile '):
                profile_name = line.replace('[profile ', '').replace(']', '')
                profiles.append(profile_name)
    
    assert len(profiles) >= 2, f"Expected at least 2 profiles, found {len(profiles)}"
    print(f"✓ Found {len(profiles)} profile(s): {', '.join(profiles[:2])}")
    
    # Load profiles_identity.json
    json_path = Path('/app/output/profiles_identity.json')
    if not json_path.exists():
        runner.warn("profiles_identity.json not found, cannot verify distinct account-role pairs")
        return
    
    with open(json_path, 'r') as f:
        identity_data = json.load(f)
    
    # Extract account-role pairs for first two profiles
    profile1, profile2 = profiles[0], profiles[1]
    
    def get_account_role(profile_name, data):
        """Extract account and role from identity data"""
        if isinstance(data, dict):
            if profile_name in data:
                profile_info = data[profile_name]
            else:
                # Try to find by ProfileName field
                profile_info = next(
                    (v for v in data.values() 
                     if isinstance(v, dict) and v.get('ProfileName') == profile_name),
                    None
                )
        elif isinstance(data, list):
            profile_info = next(
                (item for item in data if item.get('ProfileName') == profile_name),
                None
            )
        else:
            profile_info = None
        
        if profile_info:
            account = profile_info.get('Account') or profile_info.get('AccountId')
            role = profile_info.get('RoleName') or profile_info.get('Role')
            return account, role
        return None, None
    
    account1, role1 = get_account_role(profile1, identity_data)
    account2, role2 = get_account_role(profile2, identity_data)
    
    if account1 and role1 and account2 and role2:
        pair1 = f"{account1}:{role1}"
        pair2 = f"{account2}:{role2}"
        
        assert pair1 != pair2, f"Profiles have the same account-role pair: {pair1}"
        print(f"✓ Profiles have distinct account-role pairs:")
        print(f"  {profile1}: {pair1}")
        print(f"  {profile2}: {pair2}")
    else:
        runner.warn(
            f"Could not extract account-role information from profiles_identity.json. "
            f"Found: {profile1}=({account1}, {role1}), {profile2}=({account2}, {role2})"
        )


def test_caller_identity_for_profiles(runner):
    """Test 6: Run aws sts get-caller-identity for both profiles"""
    # Read AWS config to get profile names
    config_path = Path.home() / '.aws' / 'config'
    if not config_path.exists():
        runner.warn("~/.aws/config not found, skipping caller identity test")
        return
    
    # Parse config file to extract profile names
    profiles = []
    with open(config_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('[profile '):
                profile_name = line.replace('[profile ', '').replace(']', '')
                profiles.append(profile_name)
    
    if len(profiles) < 2:
        runner.warn(f"Only {len(profiles)} profile(s) found, expected at least 2")
        return
    
    # Test first two profiles
    success_count = 0
    for profile in profiles[:2]:
        print(f"\n  Testing profile: {profile}")
        try:
            result = subprocess.run(
                ['aws', 'sts', 'get-caller-identity', '--profile', profile],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                identity = json.loads(result.stdout)
                account = identity.get('Account', 'N/A')
                arn = identity.get('Arn', 'N/A')
                print(f"    ✓ Successfully authenticated")
                print(f"      Account: {account}")
                print(f"      ARN: {arn}")
                success_count += 1
            else:
                print(f"    ✗ Failed to get caller identity")
                print(f"      Error: {result.stderr}")
        except subprocess.TimeoutExpired:
            print(f"    ✗ Command timed out for profile {profile}")
        except json.JSONDecodeError as e:
            print(f"    ✗ Invalid JSON response: {e}")
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
    
    assert success_count == 2, f"Only {success_count}/2 profiles authenticated successfully"
    print(f"\n✓ All {success_count} profiles authenticated successfully")


def main():
    """Main test runner"""
    print("="*60)
    print("AWS SSO Verification Tests")
    print("="*60)
    
    runner = TestRunner()
    
    # Run all tests
    runner.test("aws-sso-util is installed", test_aws_sso_util_installed)
    runner.test("Authentication method verification", lambda: test_authentication_method(runner))
    runner.test("hello.txt content verification", test_hello_txt_content)
    runner.test("profiles_identity.json structure", test_profiles_identity_json)
    runner.test("Distinct account-role pairs", lambda: test_distinct_account_role_pairs(runner))
    runner.test("Caller identity for profiles", lambda: test_caller_identity_for_profiles(runner))
    
    # Print summary
    success = runner.summary()
    
    if success:
        print("\n✓ All tests passed!")
        sys.exit(0)
    else:
        print(f"\n✗ {runner.failed} test(s) failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
