JMount = require './index'

module.exports = class JMountSFTP extends JMount

  @share()

  @set
    encapsulatedBy  : JMount
    sharedMethods   : JMount.sharedMethods
    schema          :
      title         : { type  : String,  default   : -> @hostname }
      hostname      : { type  : String,  required  : yes }
      username      : { type  : String,  required  : yes }
      password      : { type  : String,  required  : yes }
      port          : { type  : Number,  default   : 22  } 
      initialPath   : String