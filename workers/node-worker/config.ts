export const workerConfig = {
  name: 'node-inference-worker',
  port: 5002,
  endpoint: '/analyze',
  internalNetwork: '10.0.2.0/24',
};

// RPC communication is implemented as simple internal HTTP forwarding.
