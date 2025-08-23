# Simple Python Flask app Dockerfile for Helm-M-1 prerequisite
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app.py .

# Metadata
LABEL maintainer="DevOps Test Applicant"
LABEL description="Simple Flask App for Helm Test"

# Expose the port Flask runs on
EXPOSE 5000

# Command to run the application using Flask development server
# Use gunicorn or similar for production scenarios
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
