CBucket = require '../index'

module.exports = class CGroupLeaverBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
    sharedEvents    : CBucket.sharedEvents
