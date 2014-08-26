JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  KodingError = require '../../error'

  {permit} = require '../group/permissionset'

  JPaymentPlan         = require '../payment'
  JPaymentSubscription = require '../payment/subscription'
  JVM                  = require '../vm'
  async                = require 'async'

  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedEvents      :
      static          : []
      instance        : []
    permissions       :
      'manage payment methods'  : []
      'make payments'           : []
      'manage products'         : []
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
      sharedVM        :
        type          : Boolean
        default       : no
      paymentPlan     :
        type          : String
        default       : ""
      allocation      :
        type          : Number
        default       : 0
