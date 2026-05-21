# Deployment Notes

Deployment notes should cover Terraform initialization, GCP resource creation, and service deployment patterns. The API VM is public-facing while all worker nodes are private and communicate internally.

The node-worker service should run the JavaScript worker via Node.js, not a TypeScript runtime. The service is expected to remain on port 5002 and respond at POST /analyze.
