BucketActivityDecorator = require './bucket_activity'

module.exports = class InstallsBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName = 'CInstalleeBucketActivity'
    super @data

  target:-> 'user'
  groupBy:-> 'app'
