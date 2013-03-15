class LocalStorageController extends KDController

  idPrefix = 'koding-'

  constructor:(options,data)->
    super options,data

    @storage = window["localStorage"]

    # this even will only fire when a different window changes the LS
    window.addEventListener 'storage', @storageEvent ,false

  storageEvent:(event)->
    log 'storage event found.', event

  assureStorageIndex:->
  createStorageIndex:->
  deleteStorageIndex:->

  # DELETER for key/value or set value to null
  deleteValueByKey:(key)->
    @setValueByKey key, null

  deleteValueById:(id)->
    @setValueByKey @getKeyFromId, null

  deleteKey:(key)->
    @storage.removeItem key

  deleteId:(idKey)->
    @deleteKey @getIdFromKey idKey

  # GET values from id or key
  getKeyFromId:(id)->
    id.replace idPrefix, ''

  getIdFromKey:(key)->
    @getSlug key

  getValueByIndex:(index)->
    if @storage.length > index and @storage.key index
      @storage.key index
    else null

  getValueByKey:(key)->
    @storage.getItem key

  getValueById:(id)->
    @getValueByKey @getSlug(id)

  # SETTER
  setValueByKey:(key, value)->
    @storage.setItem key,value

  setValueById:(id, value)->
    @setValueByKey @getSlug(id), value


  # SIZE related methods
  getStorageLength:->
    @storage.length

  getStorageSize:->
  getStorageRemainingSize:->
  getStorageUsedSize:->
    JSON.stringify(@storage).length # in bytes


  hasKey:(key)->
    @storage.getItem(key) isnt null

  hasId:(id)->
    @hasKey @getSlug id


  getSlug:(id)-> idPrefix+id

