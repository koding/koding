JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  @set
    limits   :
      cpu    : 'core'
      ram    : 'GB'
      disk   : 'GB'
      users  : 'user'