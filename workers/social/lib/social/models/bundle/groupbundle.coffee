JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  KodingError = require '../../error'

  {permit} = require '../group/permissionset'

  {groupBy} = require 'underscore'

  {daisy} = require 'bongo'

  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedEvents      :
      static          : []
      instance        : []
    sharedMethods     :
      static          : []
      instance        : []
    permissions       :
      'manage payment methods'  : []
      'change bundle'           : []
      'request bundle change'   : ['member','moderator']
      'commission resources'    : ['member','moderator']
    schema            :
      overagePolicy   :
        type          : String
        enum          : [
          'unknown value for overage'
          ['allowed', 'by permission', 'not allowed']
        ]
        default       : 'not allowed'
