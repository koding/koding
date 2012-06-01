class ResourceManager
  @_resources         = {}
  constructor: ->
    @_resourceInstances = {}
    
  @register: (name, resource) ->
    log 'registering re', name, resource
    ResourceManager._resources[name] = resource
    
  init: ->
    for resourceName, resourceConstructor of ResourceManager._resources
      @_add resourceName, resourceConstructor
      
    
  _add: (name, resourceConstructor) ->
    log 'adding ', name, resourceConstructor
    @_resourceInstances[name] = new resourceConstructor
    
  get: (name) ->
    @_resourceInstances[name]
    

class Resource
  constructor: (@adapter) ->
    @__items  = {}
    @_emitter = new BasicEmitter
    
  _fetch: (key, done, callback) ->
    # key = JSON.stringify options
    unless @__items[key]
      @__items[key] = 'in process'
      log 'marking in process for key', key
      callback () =>
        data = Array::slice.call(arguments)
        @__items[key] = data
        done.apply null, data
        @_emitter.emit key, data
      # @adapter.one options, (error, account) =>
      #   @__items[key] = account
      #   @_emitter.emit key, account
    else if @__items[key] is 'in process'
      log 'placing in queue'
      @_emitter.on key, (data) =>
        log 'emitting data for key', key, data
        done.apply null, data
    else
      log 'returning data for key', key
      done.apply null, @__items[key]
      
  key: ->
    key = ''
    for item in arguments
      key += JSON.stringify item
      
    key
    
      
  one: (options, done) ->
    @_fetch 'one' + @key(options), done, (callback) =>
      @adapter.one options, (error, account) =>
        callback account
        
  some: (query, options, done) ->
    @_fetch 'some' + @key(query, options), done, (callback) =>
      @adapter.some query, options, (error, accounts) =>
        callback error, accounts
        
  