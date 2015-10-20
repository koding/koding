{ generateRandomString } = require '../../index'
StackTemplate = require '../../../../social/lib/social/models/computeproviders/stacktemplate'

generateStackTemplateData = (client, data) ->

  data                         ?= {}
  { delegate }                  = client.connection
  { template, templateDetails } = data
  template                     ?= 'template content'
  templateDetails              ?= 'template details'

  return {
    originId    : delegate.getId()
    group       : client.context.group
    title       : data.title       ? generateRandomString()
    config      : data.config      ? {}
    description : data.description ? 'test stack template'
    machines    : data.machines    ? []
    accessLevel : data.accessLevel ? 'private'
    template    : StackTemplate.generateTemplateObject, template, templateDetails
    credentials : data.credentials ? 'credentials'
  }


module.exports = {
  generateStackTemplateData
}

