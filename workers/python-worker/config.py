# Python worker configuration placeholders.
# This worker remains private and does not use a public IP.
WORKER_NAME = 'python-inference-worker'
WORKER_PORT = 5001
WORKER_INTERNAL_NETWORK = '10.0.1.0/24'
NODE_WORKER_URL = 'http://127.0.0.1:5002/analyze'

# RPC communication is implemented as simple internal HTTP forwarding.
