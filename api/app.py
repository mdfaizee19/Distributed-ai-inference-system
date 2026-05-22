"""
API gateway scaffold.
This file exposes a simple local HTTP entrypoint on port 80.
The gateway forwards inference requests to the internal Python worker.
"""

from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
PY_WORKER_URL = 'http://10.0.1.9:5001/infer'

@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'component': 'api-gateway'
    })

@app.route('/infer', methods=['POST'])
def infer():
    if not request.is_json:
        return jsonify({'error': 'JSON payload required'}), 400

    payload = request.get_json()
    input_text = payload.get('input')
    if not input_text:
        return jsonify({'error': 'input field is required'}), 400

    try:
        response = requests.post(PY_WORKER_URL, json={'input': input_text}, timeout=5)
        response.raise_for_status()
        return jsonify(response.json()), response.status_code
    except requests.RequestException as exc:
        return jsonify({'error': 'Failed to reach Python worker', 'details': str(exc)}), 502

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
