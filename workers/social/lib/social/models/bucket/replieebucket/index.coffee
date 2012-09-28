CBucket = require '../index'

module.exports = class CReplieeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
  