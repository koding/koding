jraphical = require 'jraphical'

module.exports = class JProxyRule extends jraphical.Module

  {secure, ObjectId}  = require 'bongo'

  @share()

  @set
    softDelete      : no

    sharedMethods   :
      instance      : []
      static        : ['one', 'all', 'count']

    indexes         :
      name          : 'unique'

    schema          :
      
      action        :
        type        : String
        required    : yes
      enabled       :
        type        : Boolean
        default     : yes
      match         : 
        type        : String
        required    : yes

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date
