CBucket = require '../index'

module.exports = class CFollowerBucket extends CBucket
  
  @share()
  
  @set
    schema          : CBucket.schema