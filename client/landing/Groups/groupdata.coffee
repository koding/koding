class GroupData extends KDEventEmitter

  getAt:(path)->
    JsPath.getAt @data, path

  setGroup:(group)->
    @data = group
    @emit 'update'
