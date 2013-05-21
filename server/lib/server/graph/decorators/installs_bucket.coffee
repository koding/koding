BucketActivityDecorator = require './bucket_activity'

module.exports = class InstallsBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @activityName = 'CInstallerBucket'
    @bucketName   = 'CInstallerBucketActivity'
    @targetName   = 'user'
    @groupByName  = 'app'

    super @data
