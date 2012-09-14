{Model} = require 'bongo'

module.exports = class JHyperlink extends Model
  
  @share()
  
  @set
    schema    :
      url     : 
        type  : String
        url   : yes
      title   : String
      target  : 
        type  : String
        enum  : ["_blank", "_self"]
