JStorage = require './storage'

module.exports = class JCombinedAppStorage extends JStorage

  { signature, ObjectId } = require 'bongo'

  @share()

  @set
    indexes         :
      accountId     : 'unique'
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods   :
      static        : {}
       #it's secure to have save and update, since JAppStorage can only be gotten by a client that owns that appstorage
      instance      :
        save:
          (signature Function)
        update:
          (signature Object, Function)
    schema          :
      accountId     : ObjectId
      storage       : Object





