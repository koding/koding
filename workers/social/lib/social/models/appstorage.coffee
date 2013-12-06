JStorage = require './storage'

module.exports = class JAppStorage extends JStorage

  {secure} = require 'bongo'

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static      : []
       #it's secure to have save and update, since JAppStorage can only be gotten by a client that owns that appstorage
      instance    : ['save','update']
    schema        :
      appId       : String  # just the path for now
      version     :         # may be necessary in the future
        type      : String
        default   : '1.0'
      bucket      :
        type      : Object
        default   : -> {}
