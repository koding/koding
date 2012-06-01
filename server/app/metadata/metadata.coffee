class Metadata extends EventEmitter
  MetadataSchema = new Schema
    type      : String
    flags     : [Flag.schema]
    replyId   : ObjectId
    data      : Mixed
  
  @__defineGetter__ 'schema', -> MetadataSchema
  
  types = {}
  @__defineGetter__ 'types', -> types
  
  @defineFlags =(Class, flags)->
    types[Class.name] = Class
    
    if flags instanceof Flag
      oldFlags = flags
      flags = {}
      flags[Class.name] = oldFlags
    
    Class.__defineGetter__ 'flags', -> flags
  
  @attachInterfacesTo =(instance, type)->
    typeName = t type.name
    
    flagInterfaceName   = typeName.toMethodName prefix: 'flag'
    unflagInterfaceName = typeName.toMethodName prefix: 'unflag'
    
    instance[flagInterfaceName]   = instance.flag.bind    instance, type
    instance[unflagInterfaceName] = instance.unflag.bind  instance, type
  
  @filter = (metadata, account)->
    
    groups = {}
    
    for datum in metadata when fn = @types[datum.type].outputFilters.elementFilter
      (groups[datum.type] or= [])
        .push fn datum, account
    
    for own key, group of groups
      groups[key] = @types[key].outputFilters.groupFilter group
    
    groups
    
  
  constructor:(@module)->
    for metadataType in @getMetadataTypes()
      Metadata.attachInterfacesTo @, metadataType
  
  getMetadataTypes:->
    _(@module.inheritanceChain()).chain()
      .map((Class)-> Class.metadataTypes or [])
      .flatten()
      .uniq()
    .value()
  
  fetchEmbeddedDocument:(type, replyId, callback)->
    [callback, replyId] = [replyId, callback] unless callback
    
    metadata = @get()
    embeddedDoc = (embeddedDoc for embeddedDoc in metadata when embeddedDoc.type is type and embeddedDoc.replyId?.toString() is replyId)[0]
    
    if embeddedDoc
      callback null, embeddedDoc
    
    else
      @add {type, replyId}, callback
  
  flag:(metadataType, options)->
    {account, flagType, option, replyId} = options
    
    @emit 'flagisadded', options
    
    @fetchEmbeddedDocument metadataType, replyId, (err, metadata)=>
      Class = Metadata.types[ metadataType ]
      for own flagClassName, flagStructure of Class.flags when flagType is metadataType
        
        flagType = flagStructure.type or flagClassName
        
        unless flagStructure.isMultiple
          @unflag metadataType, {account, replyId}
        
        flagStructure.populate metadata, {
          id: account.getId()
          metadataType
          flagType
          replyId
          option
        }
        
        @emit 'flagwasadded', options

  unflag:(metadataType, options, callback)->
    {account, replyId} = options
  
    @emit 'flagisremoved', options
    
    @fetchEmbeddedDocument metadataType, replyId, (err, metadata)=>
      metadata.flags.forEach (flag)->
        results = flag.get 'results'
        
        for own resultKey, result of results
          flag.results[resultKey] = _(result).select (id)->
            return yes unless id?
            keepIt = not account.getId().equals id
      
      @emit 'flagwasremoved', options
    
  get:(type, replyId)->
    unless type
      @module.module.metadata
    else
      @getEmbedded type, replyId
  
  getEmbedded:(type, replyId)->
    metadata = @get()
    for datum in metadata
      
      mine = if replyId isnt 'root' then datum.replyId?.equals replyId
      
      if datum.type is type and mine or not datum.replyId
        return datum
  
  set:(id, values)->
    _(@get().id id).each (metadata)->
      for key, val in values
        metadata.set key, val
  
  push:(metadataDesc)->
    @get().push metadataDesc
  
  add:(metadataDesc, callback)->
    @push metadataDesc
    metadata = @get()[-1..][0]
    callback null, metadata
  
  # TODO:
  remove:(id, callback)->

