JBundle = require '../bundle'

module.exports = class JGroupBundle extends JBundle

  {permit} = require '../group/permissionset'

  {groupBy} = require 'underscore'

  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedEvents      :
      static          : []
      instance        : []
    sharedMethods     :
      static          : ['fetchPlans']
      instance        : ['fetchLimits', 'debit']
    permissions       :
      'manage payment methods'  : []
      'change bundle'           : []
      'request bundle change'   : ['member','moderator']
      'commission resources'    : ['member','moderator']
    limits            :
      cpu             : { unit: 'core', quota: 1 }
      ram             : { unit: 'GB',   quota: 0.25 }
      disk            : { unit: 'GB',   quota: 0.5 }
      users           : { unit: 'user', quota: 20 }
      cpuPerUser      : { unit: 'core', quota: 0, title: 'cpu per user' }
      ramPerUser      : { unit: 'GB',   quota: 0, title: 'ram per user' }
      diskPerUser     : { unit: 'GB',   quota: 0, title: 'disk per user' }
    schema            :
      overagePolicy   :
        type          : String
        enum          : [
          'unknown value for overage'
          ['allowed', 'by permission', 'not allowed']
        ]
        default       : 'not allowed'

  @parsePlanKey = (key)->
    [ prefix, category, resource, upperBound ] = key.split '_'
    return { prefix, category, resource, upperBound: +upperBound }

  @fetchPlans = permit 'commission resources',
    success: (client, callback) ->
      (require 'koding-payment').getPlans (err, plans) =>
        return callback err  if err

        formattedPlans = plans.map (plan) =>
          feeInitial  : plan.feeInitial
          feeMonthly  : plan.feeMonthly
          code        : plan.code
          usage       : @parsePlanKey plan.code
          title       : plan.title

        byCategory = groupBy formattedPlans, (plan)-> plan.usage.category

        for own category, group of byCategory
          byCategory[category] = groupBy group, (plan)-> plan.usage.resource

        callback null, byCategory


  fetchLimits$: permit 'change bundle',
    success: (client, callback)-> @fetchLimits callback

  debit$: permit 'commission resources',
    success: (client, debits, callback)->
      JVM = require '../vm'
      {connection:{delegate}, context:{group}} = client
      JVM.calculateUsage delegate, group, (err, usage)=>
        return callback err  if err?

        # TODO: we need to do some number-crunching with the usage stats

        @debit debits, callback