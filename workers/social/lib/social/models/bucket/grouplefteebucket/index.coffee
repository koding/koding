CBucket = require '../index'

module.exports = class CGroupLefteeBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
