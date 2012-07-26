
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
    planUnitName  : String
    planInterval  : JKitePlanInterval
    trialInterval : JKitePlanInterval
    unitAmountInCents:
      type        : Number
      required    : yes
    setupFee      : Number

class JKiteSubscription extends bongo.Model
  @setSchema
    planId          : String
    subscriptionKey : String

class JKiteCluster extends bongo.Model
  @share()
  
  @set
    indexes           :
      'plans.planId'  : 'unique'
    sharedMethods     :
      static          : ['create']
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
            ['roundrobin','leastconnections','fanout','globalip','random']
          ]
          default     : 'roundrobin'
        throttling    :
          unit        :
            type      : String
            enum      : [
              'invalid unit type'
              ['second','minute','hour','day','week','month','year']
            ]
          amount      : Number

  @create = bongo.secure (client, data, callback)->
    console.log data
    callback 'fuck you'