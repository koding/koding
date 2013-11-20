CBucket = require '../index'

module.exports = class CGroupJoineeBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
    sharedEvents    : CBucket.sharedEvents
