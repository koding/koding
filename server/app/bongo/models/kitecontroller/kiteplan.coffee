class JKitePlan extends bongo.Model
  @setSchema
    type      :
      type    : String
      enum    : [
        'not a valid plan type'
        ['free','paid']
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
