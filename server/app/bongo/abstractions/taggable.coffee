class Taggable

  {ObjectRef,daisy} = bongo
  {Relationship} = jraphical

  getTaggedContentRole  :-> @constructor.taggedContentRole or 'tagged'
  getTagRole            :-> @constructor.tagRole           or 'tag'

  addTags: bongo.secure (client, tags, options, callback)->
    [callback, options] = [options, callback] unless callback
    options or= silent: no
    taggedContentRole = @getTaggedContentRole()
    tagCount = 0
    @removeAllTags client, silent: tags.length > 0, (err)=>
      if err then callback err
      else unless tags.length then callback null
      else
        JTag.handleFreetags client, tags, (err, tag)=>
          if err then callback err
          else
            daisy queue = [
              =>
                @addTag tag, (err)=>
                  if err then callback err
                  else do queue.next
              =>
                tag.addContent @, {
                  as: taggedContentRole
                  respondWithCount: yes
                }, (err, count)=>
                  if err then callback err
                  else do queue.next
              =>
                incCount = {}
                incCount["counts.#{taggedContentRole}"] = 1
                tag.update $inc: incCount, (err)=>
                  if err then callback err
                  else if ++tagCount is tags.length
                    @emit 'TagsChanged', tags unless options.silent
                    callback null
            ]

  removeAllTags: bongo.secure (client, options, callback)->
    [callback, options] = [options, callback] unless callback
    options or= silent: no
    Relationship.remove $or: [{
      as        : @getTaggedContentRole()
      targetId  : @getId()
    },{
      as        : @getTagRole()
      sourceId  : @getId()
    }], (err)=>
      if err then callback err
      else
        @emit 'TagsChanged', [] unless options.silent
        callback null
