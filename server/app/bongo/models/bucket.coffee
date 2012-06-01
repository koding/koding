class CBucket extends jraphical.Module

  {Model, ObjectRef, ObjectId} = bongo

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
  
  save:(callback)->
    Model::save.call @, callback
    
  add:(item, callback)->
    @update {
      $set          :
        modifiedAt  : new Date
      $addToSet     :
        group       : ObjectRef(item)
    }, callback

class CNewMemberBucket extends CBucket
  
  @share()
  
  @set
    schema          : CBucket.schema

class CFollowerBucket extends CBucket
  
  @share()
  
  @set
    schema          : CBucket.schema


class CFolloweeBucket extends CBucket
  # 
  # @__migrate =->
  #   {mongo} = bongo
  #   db = mongo.db('localhost:27017/migrate_beta_activities')
  #   db.collection('CFolloweeBucket').find {}, (err, cursor)->
  #     cursor.each (err, bucket)->
  #       if bucket?
  #         newBucket = new CFollowerBucket
  #           anchor      : bucket.anchor
  #           group       : bucket.group
  #           sourceName  : bucket.sourceName
  #           migrant     : yes
  #           meta        :
  #             createdAt : bucket.createdAt
  #             modifiedAt: bucket.modifiedAt
  #         newBucket.save (err)->
  #           console.log err if err
  #           activity = CBucketActivity.create bucket
  #           activity.createdAt = bucket.createdAt
  #           activity.modifiedAt = bucket.modifiedAt
  #           activity.save (err)->
  #             console.log err if err
  #             activity.addSubject newBucket, (err)->
  #               console.log err if err
  #               activity.update
  #                 $set:
  #                   snapshot: JSON.stringify(newBucket)
  #                 $addToSet:
  #                   snapshotIds: newBucket.getId()
  #               , (err)-> console.log err if err
  # 
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
