getGroup = require 'app/util/getGroup'

module.exports = hasIntegration = (provider) ->
  !!getGroup().config?[provider]?.enabled
