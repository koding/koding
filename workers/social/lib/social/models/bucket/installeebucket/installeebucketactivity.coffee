CActivity = require '../../activity'
CBucketActivity = require '../../activity/bucketactivity'

module.exports = class CInstalleeBucketActivity extends CBucketActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    sharedMethods   : CActivity.sharedMethods
    relationships   : CBucketActivity.relationships
