# Gunicorn configuration for Render free tier
# The default worker timeout (30s) is not enough for TensorFlow to load on CPU.
# We increase it to 300 seconds (5 minutes) to handle cold starts.

timeout = 300         # Worker timeout in seconds (5 min for cold start)
workers = 1           # Single worker uses less RAM (important for free tier)
worker_class = "sync" # Sync workers are most stable for TensorFlow
bind = "0.0.0.0:10000"
