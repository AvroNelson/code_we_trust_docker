# ABOUTME: Dockerfile for Code We Trust web application with embedded PostgreSQL
# ABOUTME: Self-contained image with Docker-in-Docker, PostgreSQL, and Code We Trust

FROM cruizba/ubuntu-dind:latest

# Install dependencies including PostgreSQL
RUN apt-get update && \
    apt-get install -y \
    wget \
    ca-certificates \
    libicu74 \
    postgresql \
    postgresql-client \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure PostgreSQL
ENV POSTGRES_PASSWORD=CwtP0stgres1 \
    POSTGRES_USER=postgres \
    POSTGRES_DB=code-we-trust \
    PGDATA=/var/lib/postgresql/data

# Initialize PostgreSQL data directory with correct ownership
RUN mkdir -p ${PGDATA} && \
    chown -R postgres:postgres /var/lib/postgresql && \
    chmod 700 ${PGDATA}

# Create app directory
WORKDIR /app

# Download and extract CodeWeTrust binary
RUN wget https://codewetrust-dist.s3-us-west-2.amazonaws.com/CodeWeTrust_linux.tar.gz && \
    tar -xzf CodeWeTrust_linux.tar.gz && \
    rm CodeWeTrust_linux.tar.gz && \
    chmod +x CodeWeTrust

# Copy configuration and startup script
COPY appsettings.json /app/appsettings.json
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

# Expose the application port
EXPOSE 8080

# Run the startup script
CMD ["/usr/local/bin/start-services.sh"]
