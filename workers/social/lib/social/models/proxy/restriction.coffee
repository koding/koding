jraphical = require 'jraphical'

module.exports = class JProxyRestriction extends jraphical.Module

  JProxyRule = require './rule'
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
      
      domainname    : String
      rulelist      : [JProxyRule]

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date
