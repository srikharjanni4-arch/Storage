# Dockerfile for AWS SSO testing
FROM amazon/aws-cli:latest

# Install aws-sso-util
RUN yum install -y python3-pip && \
    pip3 install aws-sso-util

# Create output directory
RUN mkdir -p /app/output

# Set working directory
WORKDIR /app

# Copy test files
COPY tests/ /app/tests/
COPY git_task/ /app/

CMD ["/bin/bash"]
