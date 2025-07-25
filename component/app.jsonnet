local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.exporter_filterproxy;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('exporter-filterproxy', params.namespace);

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/exporter-filterproxy' % appPath]: app,
}
