kd = require 'kd'
JView = require 'app/jview'
Encoder = require 'htmlencode'
EnvironmentFlux = require 'app/flux/environment'

remote = require('app/remote').getInstance()
showError = require 'app/util/showError'
OutputView = require 'stacks/views/stacks/outputview'

getRepoFromQuery = (query) ->

  { repo, branch } = query

  repo = Encoder.XSSEncode repo

  if branch
    branch = Encoder.XSSEncode branch
    repo = "#{repo}/#{branch}"  if branch

  return repo


module.exports = class HomeStacksImport extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView-Stacks--import'

    super options, data

    @loader = new kd.LoaderView
      showLoader : yes
      size       :
        width    : 22
        height   : 22

    @outputView = new OutputView
      delegate: @getDelegate()
      separator: '  '


  handleQuery: (query = {}) ->

    repo = getRepoFromQuery query

    @outputView.add 'Got repo as follow:', repo

    { groupsController, router } = kd.singletons

    groupsController.ready =>

      @loader.show()
      @outputView.add 'Import in progress...'

      @importStackTemplate repo, (err, stackData) =>

        @loader.hide()

        if err
          @outputView.add 'Import failed:', err
          return

        @outputView.add 'Import successful!', stackData

        @loader.show()
        @outputView.add 'Creating stack for provided data...'

        @createStackTemplate stackData, (err, stack) =>

          if err
            @outputView.add 'Stack create failed:', err

          else
            @loader.hide()
            @outputView.add 'Stack created:', stack
            @outputView.add 'Switching to Editor...'

            kd.utils.wait 5000, ->
              router.handleRoute "/Stack-Editor/#{stack._id}"


  importStackTemplate: (repo, callback) ->

    { GitProvider } = remote.api
    GitProvider.importStackTemplateData

      provider : 'gitlab'
      url      : repo

    , callback


  createStackTemplate: (stackData, callback) ->

    { GitProvider } = remote.api
    GitProvider.createImportedStackTemplate null, stackData, (err, stack) ->

      unless err
        EnvironmentFlux.actions.loadPrivateStackTemplates()

      callback err, stack


  pistachio: ->

    '''
    <h2>Stack Importer</h2>
    {{> @loader}}
    {{> @outputView}}
    '''