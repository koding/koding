BucketActivityDecorator = require './bucket_activity'

module.exports = class InstallsBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName = 'CInstallerBucketActivity'
    super @data

  target:-> 'user'
  groupBy:-> 'app'
