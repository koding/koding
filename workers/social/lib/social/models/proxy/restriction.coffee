jraphical = require 'jraphical'

module.exports = class JProxyRestriction extends jraphical.Module

  JProxyRule = require './rule'
  {secure, ObjectId}  = require 'bongo'

  @share()

  @set
    softDelete      : no

    sharedMethods   :
      instance      : []
      static        : ['one', 'all', 'count', 'fetchRestrictionByDomain']

    indexes         :
      name          : 'unique'

    schema          :
      
      domainName    : String
      ruleList      : [JProxyRule]

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date


  @fetchRestrictionByDomain: (domainName, callback)->
    @one {domainname:domainName}, (err, restrictions)->
      return callback err if err
      callback err, restrictions