JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedEvents      :
      static          : []
      instance        : []
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

