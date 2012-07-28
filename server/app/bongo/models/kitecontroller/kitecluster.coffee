class JKitePlanInterval extends bongo.Model
  @setSchema
    unit    :
      type  : String
      enum  : [
        'invalid pricing interval'
        ['day','month']
      ]
    length  :
      type  : Number
      set   : Math.floor

class JKitePlan extends bongo.Model
  @setSchema
    type      :
      type    : String
      enum    : [
        'not a valid plan type'
        ['free','paid','protected','custom']
      ]
    name          : String
    description   : String
    planId        : String
    # planUnitName  : String
    planInterval  : JKitePlanInterval
    # trialInterval : JKitePlanInterval
    unitAmountInCents:
      type        : Number
      required    : yes
    setupFee      : Number

class JKiteSubscription extends bongo.Model
  @setSchema
    planId          : String
    subscriptionKey : String

class JKiteCluster extends bongo.Model
  crypto = require 'crypto'
  
  @share()
  
  @set
    indexes           :
      'plans.planId'  : 'unique'
    sharedMethods     :
      static          : ['create','count']
    schema            :
      connectionCount : Number
      kiteName        : String
      kites           : [String]
      plans           : [JKitePlan]
      serviceKey      : String
      loadBalancer    :
        strategy      :
          type        : String
          enum        : [
            'invalid load balancer strategy'
            ['none','roundrobin','leastconnections','fanout','globalip','random']
          ]
          default     : 'none'
        # throttling    :
        #   unit        :
        #     type      : String
        #     enum      : [
        #       'invalid unit type'
        #       ['second','minute','hour','day','week','month','year']
        #     ]
        #   amount      : Number
  
  createServiceKey =(id, kiteName)->
    crypto.createHash('md5').update(id+kiteName).digest('hex')
  
  @create = bongo.secure (client, data, callback)->
    {delegate} = client.connection
    cluster = new @ {
      kiteName        : data.kiteData.kiteName
      loadBalancer    :
        strategy      : data.kiteData.loadBalancing
      serviceKey      : createServiceKey delegate.getId(), data.kiteData.kiteName
      plans           : data.planData.map (plan)->
        name          : plan.planName
        type          : plan.type
        description   : plan.planDescription
        planId        : plan.planId
        # planUnitName  : plan.??
        planInterval  :
          unit        : plan.intervalUnit
          length      : plan.intervalLength
        # trialInterval :
        #   unit        : plan.trialUnit??
        #   length      : plan.trialLength??
        unitAmountInCents : 100 * plan.unitAmount
    }
    cluster.save (err)->
      if err
        callback err
      else
        callback null, cluster