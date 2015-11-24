remote = require('app/remote').getInstance()


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credentials, description
    title, stackTemplate, machines, config, rawContent } = data

  title or= 'Default stack template'
  config ?= stackTemplate.config ? {}

  if stackTemplate?.update

    inuse   = stackTemplate.inuse
    updated = stackTemplate._updated

    dataToUpdate = if machines \
      then { machines, config } else {
        title, template, credentials, rawContent
        templateDetails, config, description
      }

    stackTemplate.update dataToUpdate, (err, _stackTemplate) ->

      if _stackTemplate
        _stackTemplate._updated = updated
        _stackTemplate.inuse    = inuse

      callback err, _stackTemplate

  else

    remote.api.JStackTemplate.create {
      title, template, credentials, rawContent
      templateDetails, config, description
    }, callback

