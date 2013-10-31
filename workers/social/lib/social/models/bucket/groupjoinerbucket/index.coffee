CBucket = require '../index'

module.exports = class CGroupJoinerBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema