CBucket = require '../index'

module.exports = class CLikerBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
    sharedEvents    : CBucket.sharedEvents
