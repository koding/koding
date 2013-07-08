JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  KodingError = require '../../error'

  {permit} = require '../group/permissionset'

  JRecurlyPlan         = require '../recurly'
  JRecurlySubscription = require '../recurly/subscription'
  JVM                  = require '../vm'
  async                = require 'async'

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
      sharedVM        :
        type          : Boolean
        default       : no
      paymentPlan     :
        type          : String
        default       : ""
      allocation      :
        type          : Number
        default       : 0

  canCreateVM: (account, group, data, callback)->
    {type, planCode} = data

    if type is 'user'
      planOwner = "user_#{account._id}"
    else if type is 'group'
      planOwner = "group_#{group._id}"

    JRecurlySubscription.getSubscriptionsAll planOwner,
      userCode: planOwner
      planCode: planCode
      $or: [
        {status: 'active'}
        {status: 'canceled'}
      ]
    , (err, subs)=>
      return callback new KodingError "Payment backend error: #{err}"  if err

      paidVMs     = 0
      subs.forEach (sub)->
        paidVMs = sub.quantity

      createdVMs = 0
      JVM.someData
        planOwner: planOwner
        planCode : planCode
      ,
        name     : 1
      , {}, (err, cursor)=>
        cursor.toArray (err, arr)=>
          return callback err  if err

          createdVMs = arr.length
          firstVM    = group.slug is 'koding' and createdVMs == 0 and planCode is 'free'

          callback null, paidVMs > createdVMs or firstVM


  createVM: (account, group, data, callback)->
    {type, planCode} = data

    if type is 'user'
      planOwner = "user_#{account._id}"
    else if type is 'group'
      planOwner = "group_#{group._id}"

    @canCreateVM account, group, data, (err, status)=>
      return callback err  if err

      if status
        options     =
          planCode  : planCode
          usage     : {cpu: 1, ram: 1, disk: 1}
          type      : type
          account   : account
          groupSlug : group.slug

        JVM.createVm options, callback
      else
        callback new KodingError "Can't create new VM (payment missing)"