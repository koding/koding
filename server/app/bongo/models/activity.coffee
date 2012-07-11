class CActivity extends jraphical.Capsule
  {Base, ObjectId, race, dash} = bongo
  {Relationship} = jraphical
  
  @mixin Flaggable
  @::mixin Flaggable::
  
  @getFlagRole =-> 'activity'
  
  jraphical.Snapshot.watchConstructor @
  
  @share()
  
  @set
    feedable          : yes
    # indexes           :
    #   'sorts.repliesCount'  : 'sparse'
    #   'sorts.likesCount'    : 'sparse'
    #   'sorts.followerCount' : 'sparse'
    sharedMethods     :
      static          : ['one','some','all','on','someData','teasers','captureSortCounts']
      instance        : ['fetchTeaser']
    schema            :
      # teaserSnapshot  : Object
      sorts           :
        repliesCount  :
          type        : Number
          default     : 0
        likesCount    :
          type        : Number
          default     : 0
        followerCount :
          type        : Number
          default     : 0
      snapshot        : String
      snapshotIds     : [ObjectId]
      createdAt       :
        type          : Date
        default       : -> new Date
      modifiedAt      :
        type          : Date
        get           : -> new Date
      # readBy        : [bongo.ObjectId]
      originType      : String
      originId        : bongo.ObjectId
  
  # @__migrate =(callback)->
  #   @all {snapshot: $exists: no}, (err, activities)->
  #     console.log('made it here')
  #     if err
  #       callback err
  #     else
  #       activities.forEach (activity)->
  #         activity.fetchSubject (err, subject)->
  #           if err
  #             callback err
  #           else
  #             subject.fetchTeaser (err, teaser)->
  #               if err
  #                 callback err
  #               else
  #                 activity.update
  #                   $set:
  #                     snapshot: JSON.stringify(teaser)
  #                   $addToSet:
  #                     snapshotIds: subject.getId()
  #                 , callback
  
  @captureSortCounts =(callback)->
    selector = {
      type  : 'CStatusActivity'
      $or: [
        {'sorts.repliesCount' : $exists:no}
        {'sorts.likesCount'   : $exists:no}
      ]
    }
    console.log JSON.stringify selector
    @someData selector, {
      _id: 1
    }, (err, cursor)->
      if err
        callback err
      else
        queue = []
        cursor.each (err, doc)->
          if err
            callback err
          else unless doc?
            dash queue, callback
          else
            {_id} = doc
            queue.push ->
              selector2 = {
                sourceId  : _id
                as        : 'content'
              }
              Relationship.someData selector2, {
                targetName  : 1
                targetId    : 1
              }, (err, cursor)->
                if err
                  callback err
                else
                  cursor.nextObject (err, doc1)->
                    if err
                      queue.fin(err)
                    else unless doc1?
                      console.log _id, JSON.stringify selector2
                    else
                      {targetName, targetId} = doc1
                      console.log targetName
                      Base.constructors[targetName].someData {
                        _id: targetId
                      },{
                        'repliesCount'  : 1
                        'meta'          : 1
                      }, (err, doc2)->
                        if err
                          queue.fin(err)
                        else
                          {repliesCount, meta} = doc2
                          console.log 'META', meta
                          CActivity.update {_id}, $set:
                            'sort.repliesCount' : repliesCount
                            'sort.likesCount'   : meta?.likes or 0
                          , -> console.log 'hello', queue.fin()
                        
              
  
  fetchTeaser:(callback)->
    @fetchSubject (err, subject)->
      if err
        callback err
      else
        subject.fetchTeaser (err, teaser)->
          callback err, teaser
  
  @teasers =(selector, options, callback)->
    [callback, options] = [options, callback] unless callback
    @someData {snapshot:$exists:1}, {snapshot:1}, {limit:20}, (err, cursor)->
      cursor.toArray (err, arr)->
        callback null, 'feed:'+(item.snapshot for item in arr).join '\n'
  
  markAsRead: bongo.secure ({connection:{delegate}}, callback)->
    @update
      $addToSet: readBy: delegate.getId()
    , callback
  
class CRepliesActivity extends CActivity
  
  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : jraphical.Relationship
        as          : 'subject'