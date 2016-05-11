remote = require('app/remote').getInstance()
EnvironmentFlux = require 'app/flux/environment'


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credentials, description
    title, stackTemplate, machines, config, rawContent } = data

  title or= 'Default stack template'
  config ?= stackTemplate.config ? {}

  if stackTemplate?.update

    dataToUpdate = if machines \
    then { machines, config }
    else {
      title, template, credentials, rawContent
      templateDetails, config, description
    }

    EnvironmentFlux.actions.updateStackTemplate(stackTemplate, dataToUpdate)
      .then ({ stackTemplate }) -> callback null, stackTemplate
      .catch (err) -> callback err

  else

    EnvironmentFlux.actions.createStackTemplate({
      title, template, credentials, rawContent
      templateDetails, config, description
    }).then ({ stackTemplate }) ->
      callback null, stackTemplate
    .catch (err) -> callback err
