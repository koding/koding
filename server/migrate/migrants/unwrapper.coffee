class Unwrapper extends Migrant
  
  saved =(module2)->
    console.log "ModuleData for ID #{module2._id} is saved."
    
  batchdone =(limit, skip)->
    console.log "Done with a batch of #{limit}, starting with ##{skip}"
  

  finished =(total)->
    console.log "That's all! (Unwrapped #{total})"
  
  @migrate = ({limit, skip}={})->
    limit or= 100
    skip  or= 0
    unwrapper = new @ limit, skip
    unwrapper.migrate()

  constructor:(@limit, @skip)->

  initialize:->
    ModuleData_Deprecated.count {}, (err, @total)=>
      console.log @total
      throw err if err
      @initialized = yes
      @migrate()

  hasMore:->
    batchSize = @total-@skip
    if batchSize is 0 then return no
    @skip + Math.min(@limit, batchSize) <= @total

  migrate:->
    unless @initialized
      @initialize()
  
    else if @hasMore()
      skip = @skip
      ModuleData_Deprecated.find {}, [], { skip, @limit }, (err, cur)=>
        newItems = cur.length
        cur.forEach (module)=>
          for own subclass of Module.subclasses
            break if module[subclass]?.length
          
          module2 = new ModuleData
          
          _.extend module2,
            type       : subclass
            data       : module[subclass][0]
            metadata   : module.metadata
            tags       : module.tags
            createdAt  : module.createdAt
            modifiedAt : module.modifiedAt
            _id        : module._id
          
          module2.save (err)=>
            throw err if err
            saved module2
            console.log module2.type
            if ++skip is @skip + newItems
              batchdone newItems, @skip
              @skip = skip
              @migrate()

    else finished @skip