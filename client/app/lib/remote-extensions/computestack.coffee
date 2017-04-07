remote         = require('../remote')

module.exports = class JComputeStack extends remote.api.JComputeStack

  getUnreadCount: ->

    @_revisionStatus?.status?.code or 0


  getOldOwner: -> @config?.oldOwner


  isManaged: -> @title is 'Managed VMs'
