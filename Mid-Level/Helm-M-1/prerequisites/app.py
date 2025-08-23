# Simple Flask app for Helm-M-1 prerequisite
import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello_world():
    """Returns a simple greeting."""
    # Example of potentially using an environment variable later
    api_key_status = "Not Set"
    if os.environ.get('API_KEY'):
        api_key_status = "Set (Hidden)" # Don't expose the key itself

    return jsonify(
        message="Hello from the Flask app deployed via Helm!",
        version="1.0",
        api_key_status=api_key_status
    )

@app.route('/health')
def health_check():
    """Basic health check endpoint."""
    return jsonify(status="UP"), 200

if __name__ == '__main__':
    # Note: Flask's development server is not recommended for production.
    # Use a production-grade WSGI server like Gunicorn or uWSGI.
    app.run(host='0.0.0.0', port=5000, debug=False) # Turn debug off for containers