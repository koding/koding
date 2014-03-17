jraphical = require 'jraphical'
module.exports = class JKitePlan extends jraphical.Module
  {permit}            = require './group/permissionset'
  {secure, signature} = require 'bongo'
  KodingError         = require '../error'

  @share()
  @set
    permissions           :
      'list kite plans'   : ['member']
      'create kite plans' : ['member']
    schema                :
      name                : String
      description         : String
      price               : String
      recurring           : String
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedEvents          :
      instance            : []
      static              : []
    sharedMethods         :
      static:
        list:
          (signature Object, Object, Function)
        create:
          (signature Object, Function)
      instance :
        modify :
          (signature Object, Function)
