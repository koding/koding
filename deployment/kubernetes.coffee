fs            = require 'fs'
{ isAllowed } = require './grouptoenvmapping'
YAML          = require 'yamljs'

generatePodDef = (podName) ->
  podHeader =
    apiVersion      : 'v1'
    kind            : 'Pod'
    metadata        :
      name          : podName
      namespace     : 'koding'
    spec            :
      restartPolicy : 'Never'
      containers    : []

  return podHeader

generateContainerSection = (app, options = {}) ->

  container =
    name          : app
    image         : options.kubernetes.image
    workingDir    : '/opt/koding'
    command       : options.kubernetes.command

  container.ports = generatePortsSection options if options.ports
  container.volumeMounts = options.kubernetes.mounts or []

  return container

generatePortsSection = (options) ->
  return [ {
    containerPort: parseInt(options.ports.incoming, 10),
    hostPort: parseInt(options.ports.incoming, 10)
  } ]

generateVolumesSection = (KONFIG, options) ->
  return [
    { name: 'koding-working-tree', hostPath: { path: options.volumeDir } }
    { name: 'assets', hostPath: { path: options.volumeDir + '/website' } }
  ]

module.exports.create = (KONFIG, options) ->
  KONFIG.kubernetesConf = generatePodDef('backend')

  for name, workerOptions of KONFIG.workers when workerOptions.kubernetes?.command?

    unless isAllowed workerOptions.group, KONFIG.ebEnvName
      continue

    KONFIG.kubernetesConf.spec.containers.push generateContainerSection name, workerOptions

  KONFIG.kubernetesConf.spec.volumes = generateVolumesSection KONFIG, options

  return YAML.stringify(KONFIG.kubernetesConf, 4)

module.exports.createBuildPod = (KONFIG, options) ->
  buildContainer =
    name          : 'build'
    image         : 'koding/base'
    workingDir    : '/opt/koding'
    command       : [ 'scripts/bootstrap-container', 'k8s_build',
                      '--projectRoot', '/opt/koding',
                      '--volumeDir', "#{KONFIG.projectRoot}",
                      '--config', 'dev',
                      '--publicPort', '8090',
                      '--host', "#{KONFIG.domains.base}:#{KONFIG.publicPort}",
                      '--hostname', KONFIG.domains.base,
                      '--kubernetes' ]
    volumeMounts  : [ { mountPath: '/opt/koding', name: 'koding-working-tree' } ]

  KONFIG.buildPodConf = generatePodDef('workers-build')
  KONFIG.buildPodConf.spec.containers.push buildContainer

  KONFIG.buildPodConf.spec.volumes = generateVolumesSection KONFIG, options

  return YAML.stringify(KONFIG.buildPodConf, 4)

module.exports.createClientPod = (KONFIG, options) ->
  landingContainer =
    name          : 'landing'
    image         : 'koding/base'
    workingDir    : '/opt/koding'
    command       : [ 'make', '--directory', 'client/landing', 'dev' ]
    volumeMounts  : [ { mountPath: '/opt/koding', name: 'koding-working-tree' } ]

  clientContainer =
    name          : 'client'
    image         : 'koding/base'
    workingDir    : '/opt/koding'
    command       : [ 'make', '--directory', 'client', 'development' ]
    volumeMounts  : [ { mountPath: '/opt/koding', name: 'koding-working-tree' } ]

  KONFIG.clientPodConf = generatePodDef('frontend')
  KONFIG.clientPodConf.spec.containers.push landingContainer
  KONFIG.clientPodConf.spec.containers.push clientContainer

  KONFIG.clientPodConf.spec.volumes = generateVolumesSection KONFIG, options

  return YAML.stringify(KONFIG.clientPodConf, 4)
