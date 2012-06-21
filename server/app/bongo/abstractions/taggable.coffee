class Taggable
  
  getTagRole:-> @constructor.tagRole or 'tagged'
  
  addTags: bongo.secure (client, tags, callback)->
    tagRole = @getTagRole()
    tagCount = 0
    JTag.handleFreetags client, tags, (err, tag)=>
      if err
        callback err
      else
        @assureTag tag, (err)=>
          if err
            callback err
          else tag.addContent @, as: tagRole, returnCount: yes, (err, count)->
            if err
              callback err
            else
              incCount = {}
              incCount["counts.#{tagRole}"] = 1
              tag.update $inc: incCount, (err)->
                if err then callback err
                else if ++tagCount is tags.length
                  callback null