"""
Python worker scaffold.
This worker receives requests from the API gateway and forwards them to the Node worker.
"""

from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
NODE_WORKER_URL = 'http://127.0.0.1:5002/analyze'

@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'component': 'python-worker'
    })

@app.route('/infer', methods=['POST'])
def infer():
    if not request.is_json:
        return jsonify({'error': 'JSON payload required'}), 400

    payload = request.get_json()
    input_text = payload.get('input')
    if not input_text:
        return jsonify({'error': 'input field is required'}), 400

    return jsonify({
        'worker': 'python-worker',
        'result': f'processed: {input_text}'
    })

@app.route('/process', methods=['POST'])
def process():
    if not request.is_json:
        return jsonify({'error': 'JSON payload required'}), 400

    payload = request.get_json()
    prompt = payload.get('prompt')
    if not prompt:
        return jsonify({'error': 'prompt field is required'}), 400

    try:
        response = requests.post(NODE_WORKER_URL, json={'prompt': prompt}, timeout=5)
        response.raise_for_status()
        return jsonify(response.json()), response.status_code
    except requests.RequestException as exc:
        return jsonify({'error': 'Failed to reach Node worker', 'details': str(exc)}), 502

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
