# AWS SSO Testing Suite

This repository contains test verification for AWS SSO authentication using aws-sso-util.

## Test Coverage

The test suite verifies the following requirements:

1. **aws-sso-util Installation**: Confirms that `aws-sso-util` is installed and accessible
2. **Authentication Method**: Verifies that authentication was performed using `aws-sso-util login` (not `aws sso login` or other methods)
3. **hello.txt Content**: Validates that the hello.txt file exists and is readable
4. **Profiles Identity JSON**: Checks the presence and valid JSON structure of `/app/output/profiles_identity.json`
5. **Distinct Account-Role Pairs**: Ensures that two AWS profiles correspond to two distinct account-role combinations
6. **Caller Identity**: Executes `aws sts get-caller-identity` for both profiles to verify active authentication

## Running Tests

### Using Bash Script

```bash
./tests/test_aws_sso.sh
```

### Using Python Script

```bash
python3 tests/test_aws_sso.py
```

### Using Docker

```bash
# Build the container
docker build -t aws-sso-test .

# Run tests
docker run --rm -v ~/.aws:/root/.aws aws-sso-test /app/tests/test_aws_sso.sh
```

## Test Structure

### Bash Tests (`tests/test_aws_sso.sh`)
- Shell-based test suite
- Compatible with most Unix-like systems
- Uses standard tools: `jq`, `aws-cli`, `aws-sso-util`

### Python Tests (`tests/test_aws_sso.py`)
- Python 3 test suite
- More detailed error reporting
- Better cross-platform compatibility
- JSON handling built-in

## Prerequisites

- AWS CLI configured with SSO profiles
- `aws-sso-util` installed
- `jq` (for bash tests)
- Python 3.6+ (for Python tests)
- Valid AWS SSO credentials

## Expected File Structure

```
/app/
├── hello world (or hello.txt)
├── output/
│   └── profiles_identity.json
└── tests/
    ├── test_aws_sso.sh
    └── test_aws_sso.py
```

## profiles_identity.json Format

The `profiles_identity.json` file should contain profile information in one of these formats:

### Dictionary format:
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

### Array format:
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

## Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run AWS SSO Tests
  run: |
    python3 tests/test_aws_sso.py
```

## Troubleshooting

### aws-sso-util not found
Install aws-sso-util:
```bash
pip install aws-sso-util
```

### No AWS SSO cache found
Authenticate first:
```bash
aws-sso-util login --profile your-profile
```

### profiles_identity.json not found
Ensure the file exists at `/app/output/profiles_identity.json` or update the path in tests.
