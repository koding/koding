CActivity = require './index'

# CFollowerBucket = require '../bucket/followerbucket'
# CFolloweeBucket = require '../bucket/followeebucket'
# CNewMemberBucket = require '../bucket/newmemberbucket'
# CLikerBucket = require '../bucket/likerbucket'
# CLikeeBucket = require '../bucket/likeebucket'
# CReplierBucket = require '../bucket/replierbucket'
# CReplieeBucket = require '../bucket/replieebucket'

module.exports = class CBucketActivity extends CActivity

  @trait __dirname, '../../traits/flaggable'
  @trait __dirname, '../../traits/grouprelated'

  @setRelationships
    subject       :
      targetType  : [
        'CFollowerBucket'
        'CFolloweeBucket'
        'CNewMemberBucket'
        'CLikerBucket'
        'CLikeeBucket'
        'CReplierBucket'
        'CReplieeBucket'
        'CInstallerBucket'
        'CInstalleeBucket'
      ]
      as          : 'content'

  @create =({constructor:{name}})->
    new (require('bongo').Base.constructors[name+'Activity'] or this)