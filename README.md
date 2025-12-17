# Storage - AWS SSO Testing Repository

This repository contains a comprehensive test suite for verifying AWS SSO (Single Sign-On) authentication using `aws-sso-util`.

## Overview

The test suite ensures that AWS SSO authentication is properly configured and working, specifically verifying:

1. ✅ **aws-sso-util Installation**: Confirms the tool is installed
2. ✅ **Authentication Method**: Verifies authentication via `aws-sso-util login` (not `aws sso login`)
3. ✅ **Content Verification**: Validates hello.txt file existence
4. ✅ **Profile Identity**: Checks `/app/output/profiles_identity.json` structure
5. ✅ **Distinct Accounts**: Ensures two profiles use different account-role pairs
6. ✅ **Active Authentication**: Tests `aws sts get-caller-identity` for all profiles

## Quick Start

### Running Tests Locally

#### Using Python
```bash
python3 tests/test_aws_sso.py
```

#### Using Bash
```bash
./tests/test_aws_sso.sh
```

### Running Tests with Docker

```bash
# Build the test container
docker build -t aws-sso-test .

# Run tests (mount your AWS credentials)
docker run --rm \
  -v ~/.aws:/root/.aws \
  -v $(pwd):/app \
  aws-sso-test \
  /app/tests/test_aws_sso.sh
```

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── test.yml           # GitHub Actions CI/CD workflow
├── examples/
│   └── profiles_identity.json # Sample profiles configuration
├── tests/
│   ├── README.md             # Detailed test documentation
│   ├── test_aws_sso.py       # Python test suite
│   └── test_aws_sso.sh       # Bash test suite
├── Dockerfile                # Container for testing environment
└── README.md                 # This file
```

## Prerequisites

To run the tests, you need:

- **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **aws-sso-util** - `pip install aws-sso-util`
- **jq** (for bash tests) - `sudo apt-get install jq` or `brew install jq`
- **Python 3.6+** (for Python tests)
- **Configured AWS SSO profiles**

## Setting Up AWS SSO

1. Install aws-sso-util:
```bash
pip install aws-sso-util
```

2. Configure your SSO profiles in `~/.aws/config`:
```ini
[profile profile1]
sso_start_url = https://your-sso-portal.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdminRole
region = us-east-1

[profile profile2]
sso_start_url = https://your-sso-portal.awsapps.com/start
sso_region = us-east-1
sso_account_id = 987654321098
sso_role_name = DeveloperRole
region = us-west-2
```

3. Login using aws-sso-util:
```bash
aws-sso-util login --profile profile1
aws-sso-util login --profile profile2
```

## Test Details

### Test 1: aws-sso-util Installation
Verifies that `aws-sso-util` command is available and working.

### Test 2: Authentication Method
Checks for aws-sso-util specific cache files and authentication markers to ensure the correct login method was used.

### Test 3: Content Verification
Validates that hello.txt (or "hello world" file) exists and is readable.

### Test 4: Profile Identity JSON
Ensures `/app/output/profiles_identity.json` exists, is valid JSON, and contains profile information.

### Test 5: Distinct Account-Role Pairs
Verifies that at least two profiles are configured with different AWS account and role combinations.

### Test 6: Caller Identity Test
Executes `aws sts get-caller-identity` for each profile to confirm active authentication.

## CI/CD Integration

This repository includes a GitHub Actions workflow (`.github/workflows/test.yml`) that:

- Sets up Python and AWS CLI
- Installs dependencies
- Runs test validation
- Verifies script executability

## profiles_identity.json Format

The tests expect a JSON file at `/app/output/profiles_identity.json` in one of these formats:

**Dictionary Format:**
```json
{
  "profile1": {
    "Account": "123456789012",
    "RoleName": "AdminRole"
  },
  "profile2": {
    "Account": "987654321098",
    "RoleName": "DeveloperRole"
  }
}
```

**Array Format:**
```json
[
  {
    "ProfileName": "profile1",
    "Account": "123456789012",
    "RoleName": "AdminRole"
  },
  {
    "ProfileName": "profile2",
    "Account": "987654321098",
    "RoleName": "DeveloperRole"
  }
]
```

See `examples/profiles_identity.json` for a complete example.

## Troubleshooting

### aws-sso-util command not found
```bash
pip install aws-sso-util
# or
pip3 install aws-sso-util
```

### Permission denied when running scripts
```bash
chmod +x tests/test_aws_sso.sh
chmod +x tests/test_aws_sso.py
```

### No AWS SSO cache found
Authenticate first:
```bash
aws-sso-util login --profile your-profile
```

### Profiles not distinct
Ensure your AWS config has at least 2 profiles with different account IDs or role names.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests to verify
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [tests/README.md](tests/README.md) for detailed documentation
- Review AWS SSO documentation: https://docs.aws.amazon.com/singlesignon/

## References

- [aws-sso-util on GitHub](https://github.com/benkehoe/aws-sso-util)
- [AWS SSO Documentation](https://docs.aws.amazon.com/singlesignon/)
- [AWS CLI SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
