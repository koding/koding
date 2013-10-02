jraphical = require 'jraphical'

module.exports = class JStorage extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : ['updateInstance']
    sharedMethods :
      static      : []
      instance    : []
    schema        :
      name        : String
      content     :
        type      : Object
        default   : -> {}