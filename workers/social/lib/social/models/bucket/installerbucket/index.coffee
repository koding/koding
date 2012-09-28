CBucket = require '../index'

module.exports = class CInstallerBucket extends CBucket

  @share()

  @set
    schema          : CBucket.schema