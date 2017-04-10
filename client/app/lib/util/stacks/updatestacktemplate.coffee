remote = require 'app/remote'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credentials, description
    title, stackTemplate, machines, config, rawContent } = data

  title or= generateStackTemplateTitle()
  config ?= stackTemplate.config ? {}

  # Make sure it's a valid stacktemplate that can be updated
  if stackTemplate?.update?
    dataToUpdate = if machines \
    then { machines, config }
    else {
      title, template, credentials, rawContent
      templateDetails, config, description
    }

    stackTemplate.update dataToUpdate, callback

  else
    options = {
      title, template, credentials, rawContent
      templateDetails, config, description
    }

    remote.api.JStackTemplate.create options, callback
