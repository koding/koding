class ActivityResource extends Resource
  constructor: ->
    super bongo.api.JActivity
    
  read: (options, done) ->
    log 'read', @
    @_fetch 'read' + @key(options), done, (callback) =>
      @adapter.read options, (error, account) =>
        callback error, account
  
ResourceManager.register 'activity', ActivityResource