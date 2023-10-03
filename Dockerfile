# Use a smaller base image with the nightly Rust toolchain
FROM rustlang/rust:nightly as builder

# Diagnostic output for the builder stage
RUN echo "Building in the builder stage"

# Set the working directory inside the container
WORKDIR /app

# Copy only the manifest files to cache dependencies
COPY Cargo.toml Cargo.lock ./

# Build the Rust project's dependencies without the source code
RUN cargo fetch 

# Copy the entire project directory into the container
COPY . .

# Build the Rust project (without optimizations for debugging)
RUN cargo build --release

# Use an even smaller base image for the final runtime image
FROM rustlang/rust:nightly-slim as slim

# Diagnostic output for the slim stage
RUN echo "Building in the slim stage"

# Set the working directory inside the final image
WORKDIR /app

# Copy the built binary from the builder image
COPY --from=builder /app/target/release/pdf-generator ./
COPY --from=builder /app/samples ./samples/
COPY --from=builder /app/templates ./templates/

# Install wkhtmltopdf and its dependencies
RUN apt-get update && apt-get install -y wkhtmltopdf

# Clean up unnecessary files to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Specify the command to run when the container starts
CMD ["./pdf-generator"]

# Expose port 8000 for the Rust application
EXPOSE 8000

