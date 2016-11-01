remote = require 'app/remote'

module.exports = isClonedTemplate = (stackTemplate, callback) ->
  return callback no unless stackTemplate

  originalStackTemplateId = stackTemplate.config?.clonedFrom
  return callback no unless originalStackTemplateId
  remote.api.JStackTemplate.one { _id: originalStackTemplateId }, (err, template) ->
    return callback template
