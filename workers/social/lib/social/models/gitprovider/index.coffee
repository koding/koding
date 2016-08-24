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

PROVIDERS =
  gitlab  : GitLabProvider
  github  : GitHubProvider


getProvider = (options, callback) ->

  unless _provider = options.provider
    callback new KodingError 'Unknown provider'
    return

  unless provider = PROVIDERS[_provider]
    callback new KodingError 'Provider is not supported'
    return

  return provider


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
        fetchConfig:
          (signature String, Function)
        importStackTemplateData :
          (signature Object, Function)
        createImportedStackTemplate :
          (signature String, Object, Function)


  @fetchConfig = permit 'import stack template',
    success: revive {
      shouldReviveClient   : yes
      shouldReviveProvider : no
    }, (client, provider, callback) ->

      return  unless _provider = getProvider { provider }, callback

      [ err, config ] = _provider.getConfig client
      callback err, config


  @importStackTemplateData = permit 'import stack template',
    success: revive {
      shouldReviveClient   : yes
      shouldReviveProvider : no
    }, (client, importParams, callback) ->

      return  unless provider = getProvider importParams, callback

      { user } = client.r

      unless provider.importStackTemplateData importParams, user, callback
        callback new KodingError 'Invalid url or repository'


  @createImportedStackTemplate = permit 'import stack template',

    (client, title, importData, callback) ->

      { template, readme } = importData

      importData.commitId ?= importData.template.commitId

      delete importData.template
      delete importData.readme

      JStackTemplate = require '../computeproviders/stacktemplate'

      # FIXME This fields requires index or we need to
      # find a better way for this one ~ GG
      selector = {
        'config.remoteDetails.user'   : importData.user
        'config.remoteDetails.repo'   : importData.repo
        'config.remoteDetails.branch' : importData.branch
      }

      JStackTemplate.one$ client, selector, (err, stacktemplate) ->

        if not err and stacktemplate
          return callback null, stacktemplate

        requiredProviders = providersParser template.content
        requiredData      = requirementsParser template.content
        config            = {
          remoteDetails   : importData
          requiredProviders
          requiredData
        }

        description = readme.content
        rawContent  = template.content

        convertedDoc = yamlToJson Encoder.htmlDecode template.content
        if convertedDoc.err
          return callback new KodingError 'Failed to convert YAML to JSON'

        { contentObject } = convertedDoc

        addUserInputOptions contentObject, requiredData
        config.buildDuration = contentObject.koding?.buildDuration

        template = convertedDoc.content
        title  or= "#{importData.repo} Stack (#{importData.branch})"

        data = { rawContent, template, title, description, config }
        JStackTemplate.create client, data, callback
