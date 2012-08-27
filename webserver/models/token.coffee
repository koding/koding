{Model} = require 'bongo'

module.exports = class JToken extends Model
  
  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String