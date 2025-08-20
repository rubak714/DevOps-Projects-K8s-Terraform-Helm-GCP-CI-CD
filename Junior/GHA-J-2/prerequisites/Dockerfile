# Simple Dockerfile for Task GHA-J-2
# Builds a basic Nginx image serving a static file.
FROM nginx:1.25-alpine

# Copy static content into the default Nginx directory
COPY content/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Default Nginx command runs automatically
