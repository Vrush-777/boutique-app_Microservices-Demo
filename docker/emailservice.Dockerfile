# ==============================================================================
# EMAIL SERVICE DOCKERFILE (Python)
# ==============================================================================

FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY src/emailservice/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/emailservice/ .

EXPOSE 8080

# Run application
CMD ["python", "email_server.py"]