class GroupData extends KDEventEmitter

  constructor:(currentGroup="koding")->
    super
    
    KD.remote.on 'ready', =>
      KD.remote.cacheable currentGroup, (err, group)=> @setGroup group

  getAt:(path)->
    JsPath.getAt @data, path

  setGroup:(group)->
    @data = group
    @emit 'update'
