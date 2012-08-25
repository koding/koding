{Model} = require 'bongo'
class JKiteSubscription extends Model
  @setSchema
    planId        : String
    key           : String