CBucket = require '../index'

module.exports = class CGroupLeaveeBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema
