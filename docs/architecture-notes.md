# Architecture Notes

This document captures the intended architecture for a public API gateway VM with private internal worker VMs. The API gateway is public and workers remain private. Internal RPC communication will occur over private IP addresses within the shared VPC.

The internal Node worker is implemented as an Express.js service listening on port 5002, and it receives forwarded prompts from the Python worker.
