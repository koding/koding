CBucket = require '../index'

module.exports = class CLikeeBucket extends CBucket

  @share()
  
  @set
    schema          : CBucket.schema