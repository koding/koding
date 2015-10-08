remote = require('app/remote').getInstance()


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credentials, description
    title, stackTemplate, machines, config } = data

  title or= 'Default stack template'
  config ?= stackTemplate.config ? {}

  if stackTemplate?.update

    dataToUpdate = if machines \
      then { machines, config } else {
        title, template, credentials
        templateDetails, config, description
      }

    stackTemplate.update dataToUpdate, (err) ->
      callback err, stackTemplate

  else

    remote.api.JStackTemplate.create {
      title, template, credentials
      templateDetails, config, description
    }, callback

