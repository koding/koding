{ _
  expect
  withConvertedUser
  generateRandomString } = require '../../index'

JStackTemplate = require  \
  '../../../../social/lib/social/models/computeproviders/stacktemplate'


generateStackMachineData = (count = 1) ->

  machines = []
  for i in [1..count]
    machines.push
      label         : "testvm-#{i}"
      region        : 'us-east-1'
      provider      : 'aws'
      source_ami    : 'ami-a6926dce'
      instance_type : 't2.nano'

  return machines


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


createStackTemplate = (client, options, callback) ->

  stackTemplateData = generateStackTemplateData client, options

  JStackTemplate.create client, stackTemplateData, (err, stackTemplate) ->
    callback err, { stackTemplate, stackTemplateData }


withConvertedUserAndStackTemplate = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser options, (data) ->
    { client }        = data
    stackTemplateData = generateStackTemplateData client, options

    createStackTemplate client, options, (err, template) ->
      expect(err).to.not.exist
      data.stackTemplate     = template.stackTemplate
      data.stackTemplateData = template.stackTemplateData
      callback data


module.exports = {
  createStackTemplate
  generateStackMachineData
  generateStackTemplateData
  withConvertedUserAndStackTemplate
}
