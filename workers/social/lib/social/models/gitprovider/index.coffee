{ Base, signature } = require 'bongo'
Encoder             = require 'htmlencode'
Constants           = require './constants'
GitHubProvider      = require './githubprovider'
GitLabProvider      = require './gitlabprovider'
requirementsParser  = require './utils/requirementsParser'
providersParser     = require './utils/providersParser'
addUserInputOptions = require './utils/addUserInputOptions'
{ yamlToJson }      = require './utils/yamlutils'
KodingError         = require '../../error'

module.exports = class GitProvider extends Base

  @trait __dirname, '../../traits/protected'

  { revive } = require '../computeproviders/computeutils'
  { permit } = require '../group/permissionset'

  @share()

  @set

    permissions   :
      'import stack template' : [ 'member' ]

    sharedMethods :
      static      :
        importStackTemplateData :
          (signature Object, Function)
        createImportedStackTemplate :
          (signature String, Object, Function)


  @importStackTemplateData = permit 'import stack template',
    success: revive {
      shouldReviveClient   : yes
      shouldReviveProvider : no
    }, (client, importParams, callback) ->

      providers =
        gitlab  : GitLabProvider
        github  : GitHubProvider

      unless _provider = importParams.provider
        return callback new KodingError 'Unknown provider'

      provider = providers[_provider]

      unless provider
        return callback new KodingError 'Provider is not supported'

      { user } = client.r

      unless provider.importStackTemplateData importParams, user, callback
        callback new KodingError 'Invalid url'


  @createImportedStackTemplate = permit 'import stack template',

    (client, title, importData, callback) ->

      { rawContent, description } = importData
      delete importData.rawContent
      delete importData.description

      requiredProviders = providersParser rawContent
      requiredData      = requirementsParser rawContent
      config            = { requiredData, requiredProviders, importData }

      convertedDoc = yamlToJson Encoder.htmlDecode rawContent
      if convertedDoc.err
        return callback new KodingError 'Failed to convert YAML to JSON'

      { contentObject } = convertedDoc
      addUserInputOptions contentObject, requiredData
      config.buildDuration = contentObject.koding?.buildDuration

      template = convertedDoc.content
      title  or= 'Default stack template'

      JStackTemplate = require '../computeproviders/stacktemplate'
      data = { rawContent, template, title, description, config }
      JStackTemplate.create client, data, callback

