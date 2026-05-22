
# Distributed Inference Mesh

Distributed inference mesh deployed on Google Cloud Platform using Terraform, private VPC networking, internal worker communication, and a public JSON API gateway.

---

# Overview

This project demonstrates a distributed inference architecture where:

- An API Gateway VM exposes a public JSON API
- Worker VMs run inside a private subnet
- Requests are forwarded internally over the VPC network
- Infrastructure is fully reproducible using Terraform
- Services are managed using systemd

The system follows a lightweight RPC-style communication model between the gateway and internal workers.

---

# Architecture Diagram

<img width="1774" height="887" alt="image" src="https://github.com/user-attachments/assets/114c700d-5133-40f9-97c9-d81d6b6ffee0" />

---



---

# Features

- Private VPC networking
- Public API gateway
- Internal worker communication
- Terraform Infrastructure as Code
- Flask-based services
- systemd-managed services
- Reproducible deployment
- Health monitoring endpoints

---

# Infrastructure

## Cloud Provider

Google Cloud Platform (GCP)

## Provisioned Components

- Custom VPC
- Private subnet
- Firewall rules
- API Gateway VM
- Python Worker VM
- Node Worker VM

---

# VM Responsibilities

| VM | Purpose | Public Access |
|----|----------|---------------|
| API Gateway VM | Public HTTP API | Yes |
| Python Worker VM | Internal inference execution | No |
| Node Worker VM | Reserved worker node | No |

---

# Tech Stack

| Technology | Purpose |
|------------|---------|
| Terraform | Infrastructure provisioning |
| Google Cloud Platform | Cloud infrastructure |
| Python | Backend services |
| Flask | HTTP APIs |
| systemd | Process management |
| Linux | VM operating system |

---

# Project Structure

```text
distributed-inference-system/
│
├── api/
│   └── app.py
│
├── workers/
│   ├── python-worker/
│   │   ├── worker.py
│   │   ├── config.py
│   │   └── requirements.txt
│   │
│   └── node-worker/
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
├── systemd/
│   ├── api.service
│   └── python-worker.service
│
├── diagrams/
├── docs/
├── scripts/
└── README.md
```

---

# Reviewer Testing Guide

This section explains exactly how reviewers can validate the system.

---

# 1. Verify Infrastructure Deployment

Go to:

```text
Google Cloud Console -> Compute Engine -> VM Instances
```

Expected VMs:

| VM Name |
|----------|
| distributed-ai-inference-sys-api-gateway |
| distributed-ai-inference-sys-python-worker |
| distributed-ai-inference-sys-node-worker |

Expected behavior:

- Only API Gateway has public access
- Workers communicate internally through private subnet

---

# 2. Verify API Gateway Health

Run:

```bash
curl http://136.111.88.182/health
```

Expected response:

```json
{
  "component": "api-gateway",
  "status": "ok"
}
```

---

# 3. Verify Distributed Inference Flow

Run:

```bash
curl -X POST http://136.111.88.182/infer \
-H "Content-Type: application/json" \
-d "{\"input\":\"hello\"}"
```

Expected response:

```json
{
  "result": "processed: hello",
  "worker": "python-worker"
}
```

This confirms:

- Public API Gateway is reachable
- API Gateway forwards request internally
- Python worker processes inference request
- Response returns through gateway

---

# 4. Verify Internal Worker Isolation

The Python worker should NOT be publicly exposed.

Reviewers can verify:

- Worker VM exists inside private subnet
- Internal communication occurs through private IPs only
- Only API Gateway has public ingress

Example internal worker endpoint:

```text
http://10.0.1.9:5001/infer
```

This endpoint is reachable only from inside the VPC.

---

# 5. Verify systemd Services

SSH into API Gateway VM:

```bash
sudo systemctl status api.service
```

Expected:

```text
active (running)
```

---

SSH into Python Worker VM:

```bash
sudo systemctl status python-worker.service
```

Expected:

```text
active (running)
```

---

# 6. Verify Terraform Reproducibility

Inside terraform directory:

```bash
terraform init
terraform apply -var-file terraform.tfvars
```

Terraform provisions:

- VPC
- Firewall rules
- VM instances
- Internal networking

Infrastructure can be destroyed and recreated reproducibly.

---

# API Endpoints

---

## Health Endpoint

### Request

```bash
curl http://136.111.88.182/health
```

### Response

```json
{
  "component": "api-gateway",
  "status": "ok"
}
```

---

## Inference Endpoint

### Request

```bash
curl -X POST http://136.111.88.182/infer \
-H "Content-Type: application/json" \
-d "{\"input\":\"hello\"}"
```

### Response

```json
{
  "result": "processed: hello",
  "worker": "python-worker"
}
```

---

# Internal Communication Flow

```text
Client
   ->
API Gateway VM
   ->
Private VPC Request
   ->
Python Worker VM
   ->
JSON Response
```

---

# Security Design

## Public Access

Allowed:
- HTTP (80)
- SSH (22)

Only API Gateway VM is publicly exposed.

---

## Private Access

Worker nodes:
- Have private IPs only
- Are isolated inside VPC subnet
- Communicate internally

---

# Production Improvements

This implementation is intentionally lightweight for demonstration purposes.

For production deployment:

## Security

- HTTPS termination
- Identity-Aware Proxy
- Secret Manager integration
- Restricted ingress rules
- SSH hardening

## Reliability

- Health checks
- Auto-healing VMs
- Centralized logging
- Monitoring dashboards

## Scalability

- Kubernetes deployment
- Horizontal autoscaling
- Queue-based dispatching
- Service discovery

---

# Scaling for Larger Models

If inference workloads became significantly larger:

- GPU worker nodes would be introduced
- Workers would be containerized
- Model sharding would be implemented
- Distributed batching would be added
- High-performance RPC frameworks would replace Flask

---

# Deliverables Covered

## Infrastructure as Code

Terraform provisions:
- VPC
- Subnet
- Firewall rules
- Compute instances

---

## Deployment Configuration

Includes:
- systemd services
- Startup scripts
- Worker deployment logic

---

## Public JSON API

Implemented through Flask API Gateway.

---

## Architecture Diagram

Included in repository.

---

# Author

Mohamed Faizee

GitHub:
https://github.com/mdfaizee19
