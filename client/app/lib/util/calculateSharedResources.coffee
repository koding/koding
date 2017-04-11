debug = require('debug')('util:calculateSharedResources')

module.exports = calculateSharedResources = (props, state) ->

  debug 'start calculating shared resources', { props, state }

  resources =
    permanent: props.machines.filter (m) -> m.getType() is 'shared'
    collaboration: props.machines.filter (m) -> m.getType() is 'collaboration'

  debug 'shared resources are calculated', resources

  return resources
