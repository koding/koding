remote = require 'app/remote'

module.exports = isClonedTemplate = (stackTemplate, callback) ->
    return  unless stackTemplate

    originalStackTemplateId = stackTemplate.config?.clonedFrom
    return  unless originalStackTemplateId
    remote.api.JStackTemplate.one { _id: originalStackTemplateId }, (err, template) ->
      return callback()  if template
      return
