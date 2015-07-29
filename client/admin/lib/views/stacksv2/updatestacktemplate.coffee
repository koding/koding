remote = require('app/remote').getInstance()


module.exports = updateStackTemplate = (data, callback) ->

  { template, templateDetails, credential
    title, stackTemplate, machines } = data

  title     or= 'Default stack template'
  credentials = [credential.publicKey]  if credential

  if stackTemplate?.update
    dataToUpdate = if machines \
      then {machines} else {title, template, credentials, templateDetails}
    stackTemplate.update dataToUpdate, (err) ->
      callback err, stackTemplate
  else
    remote.api.JStackTemplate.create {
      title, template, credentials, templateDetails
    }, callback

