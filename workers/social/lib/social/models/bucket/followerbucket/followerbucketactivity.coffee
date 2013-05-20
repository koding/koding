CBucketActivity = require '../../activity/bucketactivity'
CActivity = require '../../activity'

module.exports = class CFollowerBucketActivity extends CBucketActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    sharedEvents    : CActivity.sharedEvents
    sharedMethods   : CActivity.sharedMethods
    relationships   : CBucketActivity.relationships
