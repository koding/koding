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