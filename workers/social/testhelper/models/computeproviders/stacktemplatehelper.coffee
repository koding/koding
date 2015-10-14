{ _
  expect
  withConvertedUser
  generateRandomString } = require '../../index'
JStackTemplate = require '../../../../social/lib/social/models/computeproviders/stacktemplate'


generateStackTemplateData = (client, data) ->

  data        ?= {}
  { delegate } = client.connection
  details      = 'template details'
  content      = 'template content'
  rawContent   = 'template raw content'


  stackTemplate =
    group           : client.context.group
    title           : generateRandomString()
    config          : {}
    originId        : delegate.getId()
    machines        : []
    template        : content
    rawContent      : rawContent
    description     : 'test stack template'
    accessLevel     : 'private'
    credentials     : 'credentials'
    templateDetails : details

  stackTemplate = _.extend stackTemplate, data

  return stackTemplate


withConvertedUserAndStackTemplate = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser (data) ->
    { client }        = data
    stackTemplateData = generateStackTemplateData client, options

    JStackTemplate.create client, stackTemplateData, (err, stackTemplate) ->
      expect(err).to.not.exist
      data.stackTemplate = stackTemplate
      callback data


module.exports = {
  generateStackTemplateData
  withConvertedUserAndStackTemplate
}

