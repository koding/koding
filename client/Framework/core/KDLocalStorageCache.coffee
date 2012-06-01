class KDLocalStorageCache
  # 
  # cache = {}
  # 
  # getIdFromKey = (key)->
  #   key.split('.')[1..].join('.')
  # 
  # getTimestampFromKey = (key)->
  #   key.split('.')[0]
  # 
  # cacheDataFromLocalStorage = (key)->
  #   try
  #     cache[getIdFromKey key] =
  #       timestamp : getTimestampFromKey key
  #       data      : JSON.parse localStorage[key]
  #   catch e
  #     #delete cache[getIdFromKey key]
  #     #localStorage.removeItem key
  #     log 'broken object in localstorage:::' + e.message
  # 
  # clearOldest = (howMany)->
  #   Object
  #     .keys(localStorage)
  #     .sort()
  #     .slice(-howMany)
  #     .forEach (key)->
  #       localStorage.removeItem key
  # 
  # addJSON = (id, json)->
  #   try
  #     localStorage[Date.now()+'.'+id] = json
  #   catch err
  #     if err.code is 22
  #       clearOldest 500
  #       addJSON id, json
  #     else throw err
  # 
  # @addObject = (obj)->
  #   return unless obj.id and obj.item
  #   addJSON obj.id, JSON.stringify obj.item
  # 
  # @retrieveObject = (id)->
  #   return obj if obj = cache[id]
  #   for own key in Object.keys localStorage when id is getIdFromKey key
  #     cacheDataFromLocalStorage key
  # 
  # Object
  #   .keys(localStorage)
  #   .forEach (key)->
  #     cacheDataFromLocalStorage key
      
class KDLocalStorageSpace
  
  #destroy everything in localStorage
  @clear: ->
    localStorage.clear()
  
  constructor: (space)->
    @_spaceName = space
    @_writable  = yes
    
  setWritable: (writable) ->
    @_writable = writable
    @
    
  set: (key, value) ->
    return unless @_writable
    
    try
      stringValue = JSON.stringify value
    catch e
      warn 'value ', value, 'could not be stringified'
      stringValue = ''

    localStorage["#{@_spaceName}.#{key}"] = stringValue
    
  clean: ->
    keys = Object.keys(localStorage)
    for key in keys
      if key.split('.')[0] is @_spaceName
        localStorage.removeItem key
    
  get: (key, defaultValue = null) ->
    value = localStorage["#{@_spaceName}.#{key}"]
    try
      if not value
        object = defaultValue
      else
        object = JSON.parse value
    catch e
      warn 'parse with error'
      object = defaultValue

    object
    
#######
### cached resource prototyping
####### 

class CacheableResult extends BasicEmitter
  constructor: ->
    @_result = null
    super
    
  ready: (callback) ->
    if @_result
      callback.apply null, @_result
    else
      @on 'ready', callback
    
  setResult: (result) ->
    @_result = result
    @emit.apply @, ['ready'].concat(@_result)
    
    
class CacheableResource extends KDObject
  constructor:  ->
    super
    # @_cacheIds = {}
    @_resultIds = {}
    
  id: (id) ->
    unless @_resultIds[id]
      @_resultIds[id] = new CacheableResult
      @resource.some {_id: id}, {limit: 1}, (error, result) =>
        result = [null] unless result
        @_resultIds[id].setResult [error, result.shift()]
        
    @_resultIds[id]
    
    
class CacheableAccount extends CacheableResource
  constructor: ->
    @resource = bongo.api.JAccount
    super
    
class Cacheable
  constructor: ->
    window.cache = @
    
  init: ->
    @add 'account', new CacheableAccount
    
  add: (name, resource) ->
    @[name] = resource