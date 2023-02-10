local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.exporter_filterproxy;

local commonLabels = {
  'app.kubernetes.io/name': 'exporter-filterproxy',
  'app.kubernetes.io/managed-by': 'syn',
};

local service_account = kube.ServiceAccount('exporter-filterproxy') {
  metadata+: {
    namespace: params.namespace,
    labels+: commonLabels,
  },
};
local cluster_role = kube.ClusterRole('syn-exporter-filterproxy') {
  metadata+: {
    labels+: commonLabels,
  },
  rules: [
    {
      nonResourceURLs: [ '/metrics' ],
      verbs: [ 'get' ],
    },
  ],
};
local cluster_role_binding = kube.ClusterRoleBinding('syn-exporter-filterproxy') {
  metadata+: {
    labels+: commonLabels,
  },
  subjects_: [ service_account ],
  roleRef_: cluster_role,
};


local config = kube.ConfigMap('exporter-filterproxy') {
  metadata+: {
    namespace: params.namespace,
    labels+: commonLabels,
  },
  data: {
    'config.yml': std.manifestYamlDoc(params.config {
      addr: ':80',
    }),
  },
};

local deployment = kube.Deployment('exporter-filterproxy') {
  metadata+: {
    namespace: params.namespace,
    labels+: commonLabels,
  },
  spec+: {
    replicas: params.replicas,
    template+: {
      metadata+: {
        annotations+: {
          configHash: std.md5(config.data['config.yml']),  // This makes sure we restart the pods when the configmap changed
        },
      },
      spec+: {
        containers_+: {
          proxy: kube.Container('proxy') {
            image: '%(registry)s/%(repository)s:%(tag)s' % params.images.exporter_filterproxy,
            args: [ '--config', '/etc/config/config.yml' ],
            resources: params.resources,
            securityContext: {
              runAsNonRoot: true,
            },
            ports_: {
              metrics: {
                containerPort: 80,
              },
            },
            volumeMounts_: {
              config: {
                mountPath: '/etc/config',
              },
            },
          },
        },
        serviceAccountName: service_account.metadata.name,
        volumes_: {
          config: {
            configMap: {
              name: config.metadata.name,
            },
          },
        },
      },
    },
  },
};

local service = kube.Service('exporter-filterproxy') {
  metadata+: {
    namespace: params.namespace,
    labels+: commonLabels,
  },
  target_pod: deployment.spec.template,
};

{
  '01_namespace': kube.Namespace(params.namespace),
  '02_cluster_role': cluster_role,
  '02_serviceaccount': service_account,
  '02_cluster_role_binding': cluster_role_binding,
  '03_configmap': config,
  '03_deployment': deployment,
  '03_service': service,
}
