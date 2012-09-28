JMount = require './index'

module.exports = class JMountS3 extends JMount
  
  @share()

  @set
    encapsulatedBy  : JMount
    sharedMethods   : JMount.sharedMethods
    schema          :
      title         : { type  : String,  default   : -> @hostname }
      accessKeyId   : { type  : String,  required  : yes }
      secret        : { type  : String,  required  : yes }
      initialPath   : String
