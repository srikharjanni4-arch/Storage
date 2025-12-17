# Dockerfile for AWS SSO testing
FROM python:3.9-slim

# Install AWS CLI and dependencies
RUN apt-get update && \
    apt-get install -y curl unzip jq && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    apt-get clean

# Install aws-sso-util
RUN pip3 install --no-cache-dir aws-sso-util

# Create output directory
RUN mkdir -p /app/output

# Copy application files
COPY . /app/

WORKDIR /app

CMD ["/bin/bash"]
