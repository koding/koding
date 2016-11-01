remote = require 'app/remote'
isGroupDisabled = require 'app/util/isGroupDisabled'

module.exports = class JGroup extends remote.api.JGroup

  isDisabled: -> isGroupDisabled this

