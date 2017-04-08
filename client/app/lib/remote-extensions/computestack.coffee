debug = (require 'debug')('remote:api:jcredential')
remote = require('../remote')


module.exports = class JComputeStack extends remote.api.JComputeStack

  getUnreadCount: -> @_revisionStatus?.status?.code or 0


  isManaged: -> @title is 'Managed VMs'


  getOldOwner: -> @config?.oldOwner
