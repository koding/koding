CBucket = require '../index'

module.exports = class CNewMemberBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
    sharedEvents    : CBucket.sharedEvents
