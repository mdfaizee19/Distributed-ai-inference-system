# distributed-ai-inference-system

## Overview
This repository contains a scaffold for a GCP-based distributed AI inference infrastructure assignment. The design focuses on a public API gateway VM, private worker VMs, internal-only communication, and reusable Terraform deployment.

## Architecture
The architecture separates responsibilities across a public-facing API gateway and private worker nodes. The API gateway receives external requests, validates them, and then routes tasks to private workers in an internal network.

## Infrastructure
Infrastructure is defined with Terraform in the `terraform/` directory. It includes:
- GCP provider configuration
- VPC and subnet definitions
- Firewall rules for public API access and private worker communication
- Compute Engine VM provisioning for API gateway and workers

## GCP Networking Design
- A single VPC hosts both public and private resources.
- The API gateway VM receives a public/external IP and handles inbound HTTP requests.
- Worker VMs are deployed to private subnets with no external IP.
- Worker-to-worker and API-to-worker communication is restricted to private IPs.

## Deployment Steps
1. Configure `terraform/terraform.tfvars` with your GCP project values.
2. Run `terraform init` in `terraform/`.
3. Run `terraform apply` to create the network and VM resources.
4. Deploy the API VM and worker code using the scripts in `scripts/`.
5. Enable and start the systemd services on the target VMs.

## API Usage
The API gateway exposes a public POST `/infer` endpoint. The gateway forwards internal requests to the Python worker, which in turn forwards them to the Node worker.

Example request payload:
```json
{
  "prompt": "hello"
}
```

The final response is returned from the Node worker through the API gateway.

## Local Development
Run the services locally in separate terminals.

1. Install API dependencies:
   ```bash
   python -m pip install -r api/requirements.txt
   ```
2. Install Python worker dependencies:
   ```bash
   python -m pip install -r workers/python-worker/requirements.txt
   ```
3. Install Node worker dependencies:
   ```bash
   cd workers/node-worker
   npm install
   ```
4. Start the Node worker:
   ```bash
   node worker.js
   ```
5. Start the Python worker:
   ```bash
   python workers/python-worker/worker.py
   ```
6. Start the API gateway:
   ```bash
   python api/app.py
   ```

## Architecture Flow
Local service flow:

Internet
↓
Public API Gateway VM (Flask on port 80)
↓
Internal Python Worker (Flask on port 5001)
↓
Internal Node Worker (Express on port 5002)

Each component is a simple HTTP service forwarding requests downstream.

## Port Mapping
- API Gateway: port 80
- Python Worker: port 5001
- Node Worker: port 5002

## Local Testing Example
Run the services and then execute:
```bash
curl -X POST http://127.0.0.1/infer \
  -H "Content-Type: application/json" \
  -d '{"prompt":"hello"}'
```

Expected response:
```json
{
  "result": "Processed by Node worker",
  "input": "hello"
}
```

## Terraform Setup
Terraform files include provider setup, variable declarations, the main infrastructure definition, and output values. Keep sensitive data out of version control and use `terraform.tfvars` for environment-specific values.

## Production Improvements
- Add secure service account handling and limited IAM permissions.
- Implement health checks for both API and worker services.
- Use private DNS and proper internal service discovery.
- Add logging, monitoring, and alerting for VM instances.

## Scaling Considerations
- Scale worker VMs horizontally in the private subnet.
- Consider instance groups or autoscaling for production workloads.
- Keep the API gateway lightweight and route work to private compute resources.
