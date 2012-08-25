{Model} = require 'bongo'
class JKiteConnection extends Model
  @setSchema
    username  : String
    kiteName  : String
    kiteUri   : String