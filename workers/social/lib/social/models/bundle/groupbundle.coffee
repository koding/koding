JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  {permit} = require '../group/permissionset'

  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedEvents      :
      static          : []
      instance        : []
    sharedMethods     :
      static          : []
      instance        : ['fetchLimits']
    permissions       :
      'manage payment methods'  : []
      'change bundle'           : []
      'request bundle change'   : ['member','moderator']
    limits            :
      cpu             : 'core'
      ram             : 'GB'
      disk            : 'GB'
      users           : 'user'
    schema            :
      overagePolicy   :
        type          : String
        enum          : [
          'unknown value for overage'
          ['allowed', 'by permission', 'not allowed']
        ]
        default       : 'not allowed'

  @fetchLimits$ = permit 'change bundle',
    success: (client, callback)-> @fetchLimits callback