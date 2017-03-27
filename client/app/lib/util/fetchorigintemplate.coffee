kd = require 'kd'

module.exports = fetchOriginTemplate = (stackTemplate, callback) ->

  return callback null  unless stackTemplate

  originalStackTemplateId = stackTemplate.config?.clonedFrom
  return callback null  unless originalStackTemplateId

  cc = kd.singletons.computeController
  cc.fetchStackTemplate originalStackTemplateId, callback
