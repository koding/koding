debug  = (require 'debug') 'remote:api:jgroup'
remote = require 'app/remote'
isGroupDisabled = require 'app/util/isGroupDisabled'

module.exports = class JGroup extends remote.api.JGroup

  isDisabled: -> isGroupDisabled this

  @one = ->
    debug 'one called'
    console.trace()
    super
