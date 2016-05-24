kd = require 'kd'
remote = require('app/remote').getInstance()
EnvironmentFlux = require 'app/flux/environment'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'


module.exports = updateStackTemplate = (data, callback) ->

  { reactor } = kd.singletons

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
    EnvironmentFlux.actions.updateStackTemplate(stackTemplate, dataToUpdate)
      .then ({ stackTemplate }) ->
        stackTemplate.on 'update', (data) ->
          if 'accessLevel' in data
            template = stackTemplate
            reactor.dispatch 'REMOVE_STACK_TEMPLATE_SUCCESS', { template }
        callback null, stackTemplate
      .catch (err) -> callback err

  else

    EnvironmentFlux.actions.createStackTemplate({
      title, template, credentials, rawContent
      templateDetails, config, description
    }).then ({ stackTemplate }) ->
      callback null, stackTemplate
    .catch (err) -> callback err
