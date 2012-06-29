class CBucket extends jraphical.Module

  {Model, ObjectRef, ObjectId, dash} = bongo

  @set
    broadcastable   : yes
    schema          :
      anchor        : ObjectRef
      group         : [ObjectRef]
      groupedBy     : String
      sourceName    : String # TODO: not sure if this is correct - C.T.
      snapshot      : String
      snapshotIds   : [ObjectId]
      migrant       : Boolean
      meta          : require "bongo/bundles/meta"
  
  getBucketConstructor =(groupName, role)->
    switch role
      when 'follower'
        switch groupName
          when 'source' then CFolloweeBucket
          when 'target' then CFollowerBucket
      when 'like'
        switch groupName
          when 'source' then CLikeeBucket
          when 'target' then CLikerBucket
      when 'reply'
        switch groupName
          when 'source' then CReplieeBucket
          when 'target' then CReplierBucket
          
  
  addToBucket =do ->
    # @helper
    addIt = (bucket, anchor, item, callback)->
      bucket.add item, (err)->
        if err
          callback err
        else
          jraphical.Relationship.one {
            targetId: bucket.getId()
            sourceName: bucket.constructor.name + 'Activity'
            as: 'content'
          }, (err, rel)->
            if err
              callback err
            else if rel
              konstructor = bongo.Base.constructors[rel.sourceName]
              konstructor.one _id: rel.sourceId, (err, activity)->
                if err
                  callback err
                else
                  anchor.assureActivity activity, (err)->
                    if err
                      callback err
                    else
                      callback null, bucket
            else
              activity = CBucketActivity.create bucket
              activity.save (err)->
                if err
                  callback err
                else
                  anchor.addActivity activity, (err)->
                    if err
                      callback err
                    else
                      activity.addSubject bucket, (err)->
                        if err
                          callback err
                        else
                          activity.update
                            $set          :
                              snapshot    : JSON.stringify(bucket)
                            $addToSet     :
                              snapshotIds : bucket.getId()
                          , (err)->
                            if err
                              callback err
                            else
                              callback null, bucket

    (groupName, relationship, item, anchor, callback)->
      today = $gte: new Date Date.now() - 1000*60*60*12
      bucketConstructor = getBucketConstructor(
        groupName, relationship.getAt('as')
      )
      existingBucketSelector = {
        groupedBy   : groupName
        sourceName  : relationship.sourceName
        'anchor.id' : relationship[groupName+'Id']
        'meta.createdAt'   : today
      }
      bucketConstructor.one existingBucketSelector, (err, bucket)->
        if err then callback err
        else if bucket
          addIt bucket, anchor, item, callback
        else
          bucket = new bucketConstructor
            groupedBy         : groupName
            sourceName        : relationship.sourceName
            anchor            :
              constructorName : relationship[groupName+'Name']
              id              : relationship[groupName+'Id']

          bucket.save (err)->
            if err then callback err
            else addIt bucket, anchor, item, callback

  # @helper  
  @addActivities =(relationship, source, target, callback)->
    queue = []
    fin = -> queue.fin()
    queue.push -> addToBucket 'source', relationship, target, source, fin
    queue.push -> addToBucket 'target', relationship, source, target, fin
    dash queue, callback
  # save:(callback)->
  #   Model::save.call @, callback
  #   
  add:(item, callback)->
    member = ObjectRef(item)
    @update {
      $set          :
        modifiedAt  : new Date
      $addToSet     :
        group       : member.data
    }, (err)=>
      @emit 'ItemWasAdded', member.data
      callback err

class CNewMemberBucket extends CBucket
  
  @share()
  
  @set
    schema          : CBucket.schema

class CFollowerBucket extends CBucket
  
  @share()
  
  @set
    schema          : CBucket.schema


class CFolloweeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema

class CReplierBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
  
class CReplyeeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
  
class CLikerBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
  
class CLikeeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema

class CBucketActivity extends CActivity
  
  @setRelationships
    subject       :
      targetType  : [CFollowerBucket, CFolloweeBucket, CNewMemberBucket]
      as          : 'content'

  @create =({constructor:{name}})->
    new (bongo.Base.constructors[name+'Activity'] or @)

class CNewMemberBucketActivity extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CFolloweeBucketActivity extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CFollowerBucketActivity extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CReplierBucket extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CReplieeBucket extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CLikerBucket extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

class CLikeeBucket extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   : CBucketActivity.relationships

