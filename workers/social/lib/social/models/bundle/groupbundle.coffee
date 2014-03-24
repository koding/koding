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

#  canCreateVM: (account, group, data, callback) ->
#    { type, planCode, paymentMethodId } = data
#
#    JPaymentSubscription.fetchAllSubscriptions
#      # paymentMethodId: paymentMethodId
#      planCode: planCode
#      $or: [
#        {status: 'active'}
#        {status: 'canceled'}
#      ]
#    , (err, subs) =>
#      return callback new KodingError "Payment backend error: #{err}"  if err
#
#      paidVMs = 0
#      subs.forEach (sub) ->
#        paidVMs = sub.quantity
#
#      selector    =
#        planOwner : paymentMethodId
#        planCode  : planCode
#
#      JVM.count selector, (err, count = 0) ->
#        return callback err  if err
#
#        firstVM = group.slug in ['koding','guests'] and
#                  count is 0 and planCode is 'free'
#
#        callback null, paidVMs > count or firstVM
#
#
#  createVM: (account, group, data, callback) ->
#    { planCode } = data
#
#    @canCreateVM account, group, data, (err, status) =>
#      return callback err  if err
#
#      if status
#        options     =
#          planCode  : planCode
#          usage     : { cpu: 1, ram: 1, disk: 1 }
#          account   : account
#          groupSlug : group.slug
#
#        JVM.createVm options, callback
#      else
#        callback new KodingError "Can't create new VM (payment missing)"
