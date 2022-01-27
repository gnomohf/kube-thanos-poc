// THANOS EXAMPLE

local t = import 'kube-thanos/thanos.libsonnet';


// For an example with every option and component, please check all.jsonnet

local commonConfig = {
  config+:: {
    local cfg = self,
    namespace: 'monitoring',
    version: 'v0.22.0',
    image: 'quay.io/thanos/thanos:' + cfg.version,
    objectStorageConfig: {
      name: 'thanos-objectstorage',
      key: 'thanos.yaml',
    },
    hashringConfigMapName: 'hashring-config',
    volumeClaimTemplate: {
      spec: {
        accessModes: ['ReadWriteOnce'],
        resources: {
          requests: {
            storage: '10Gi',
          },
        },
      },
    },
  },
};

local i = t.receiveIngestor(commonConfig.config {
  replicas: 1,
  replicaLabels: ['receive_replica'],
  replicationFactor: 1,
  // Disable shipping to object storage for the purposes of this example
  objectStorageConfig: null,
});

local r = t.receiveRouter(commonConfig.config {
  replicas: 1,
  replicaLabels: ['receive_replica'],
  replicationFactor: 1,
  // Disable shipping to object storage for the purposes of this example
  objectStorageConfig: null,
  endpoints: i.endpoints,
});

local s = t.store(commonConfig.config {
  replicas: 1,
  serviceMonitor: true,
});

local sc = t.sidecar(commonConfig.config{
  podLabelSelector: { prometheus : 'perro'},
},);

# Esto es para meter el sidecar como store endpoint (pa' ver metricas de prometheus)
local sidecarEndpoint =  { endpoint:: ['dnssrv+_grpc._tcp.%s.%s.svc.cluster.local:%d' % [sc.service.metadata.name, sc.config.namespace, sc.config.ports.grpc]]};

local q = t.query(commonConfig.config {
  replicas: 1,
  replicaLabels: ['prometheus_replica', 'rule_replica'],
  serviceMonitor: true,
 
  stores: [s.storeEndpoint] + i.storeEndpoints + sidecarEndpoint.endpoint, 
});



{ ['thanos-query-' + name]: q[name] for name in std.objectFields(q) } +
{ ['thanos-store-' + name]: s[name] for name in std.objectFields(s) } +
{ ['thanos-sidecar-' + name]: sc[name] for name in std.objectFields(sc) }



#{ ['thanos-query-' + name]: q[name] for name in std.objectFields(q) } +
#{ ['thanos-receive-router-' + resource]: r[resource] for resource in std.objectFields(r) } +
#{ ['thanos-receive-ingestor-' + resource]: i[resource] for resource in std.objectFields(i) if resource != 'ingestors' } +
#{
#  ['thanos-receive-ingestor-' + hashring + '-' + resource]: i.ingestors[hashring][resource]
#  for hashring in std.objectFields(i.ingestors)
#  for resource in std.objectFields(i.ingestors[hashring])
#  if i.ingestors[hashring][resource] != null
#}