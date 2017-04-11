# coffeelint: disable=newlines_after_classes
# above coffeelint ignore is required to get things passed, because i have no
# idea why this is happening. ~Umut
debug = (require 'debug')('remote:api:jcredential')
remote = require('../remote')


module.exports = class JComputeStack extends remote.api.JComputeStack

  getUnreadCount: -> @_revisionStatus?.status?.code or 0


  isManaged: -> @getAt('title') is 'Managed VMs'


  getOldOwner: -> @getAt 'config.oldOwner'
