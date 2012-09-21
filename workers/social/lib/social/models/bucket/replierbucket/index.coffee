CBucket = require '../index'

module.exports = class CReplierBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
  