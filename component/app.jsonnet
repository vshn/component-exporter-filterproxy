local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.exporter_filterproxy;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('exporter-filterproxy', params.namespace);

{
  'exporter-filterproxy': app,
}
