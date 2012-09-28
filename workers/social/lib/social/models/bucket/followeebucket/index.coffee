CBucket = require '../index'

module.exports = class CFolloweeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema
