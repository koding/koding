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
      content     :
        type      : Object
        default   : -> {}