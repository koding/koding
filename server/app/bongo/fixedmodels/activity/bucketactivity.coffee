CActivity = require './index'

module.exports = class CBucketActivity extends CActivity
  
  @setRelationships
    subject       :
      targetType  : [
        CFollowerBucket
        CFolloweeBucket
        CNewMemberBucket
        CLikerBucket
        CLikeeBucket
        CReplierBucket
        CReplieeBucket
      ]
      as          : 'content'

  @create =({constructor:{name}})->
    new (bongo.Base.constructors[name+'Activity'] or @)