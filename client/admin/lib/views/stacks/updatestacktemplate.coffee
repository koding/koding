remote = require('app/remote').getInstance()


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credentials
    title, stackTemplate, machines, config } = data

  title or= 'Default stack template'

  if stackTemplate?.update

    dataToUpdate = if machines \
      then { machines } else {
        title, template, credentials, templateDetails, config
      }

    stackTemplate.update dataToUpdate, (err) ->
      callback err, stackTemplate

  else

    remote.api.JStackTemplate.create {
      title, template, credentials, templateDetails, config
    }, callback

