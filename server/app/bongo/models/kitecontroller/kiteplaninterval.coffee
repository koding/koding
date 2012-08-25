{Model} = require 'bongo'
class JKitePlanInterval extends Model
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