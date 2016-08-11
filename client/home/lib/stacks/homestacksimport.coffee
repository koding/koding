kd = require 'kd'
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

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView-Stacks--import'

    super options, data


  viewAppended: ->

    @addSubView new kd.CustomHTMLView
      tagName: 'h2'
      partial: "Stack Importer"

    @addSubView @loader = new kd.LoaderView
      showLoader : yes
      size       :
        width    : 22
        height   : 22

    @addSubView @message = new kd.CustomHTMLView
      tagName: 'p'
      partial: "Loading..."

    @addSubView @outputView = new OutputView
      delegate: @getDelegate()
      cssClass: 'hidden'
      separator: '  '

    @addSubView @actionButton = new kd.ButtonView
      cssClass : 'GenericButton HomeAppView-Stacks--actionButton hidden'
      title: 'Open GitLab'

    remote.api.GitProvider.fetchConfig 'gitlab', (err, config) =>

      @loader.hide()

      if err
        @message.updatePartial err.message ? 'This integration is not enabled.'
        return

      { host } = config
      _host    = "http://#{host}"  # FIXME Add protocol support ~ GG

      @actionButton.show()
      @actionButton.setTitle 'Open GitLab'
      @actionButton.setCallback -> window.open _host, '_blank'

      @message.updatePartial """
        This tool is intended to use with GitLab integration which is enabled
        for this team on <a href="#{_host}">#{host}</a>. You can use action
        endpoints provided in your GitLab service to be able to use this tool
        to try your projects on Koding.
      """

      @emit 'ready'


  handleQuery: (query = {}) -> @ready =>

    repo = getRepoFromQuery query

    @message.hide()
    @actionButton.hide()

    @outputView.show()
    @outputView.add 'Got repo as follow:', repo

    { groupsController, router } = kd.singletons

    groupsController.ready =>

      @loader.show()
      @outputView.add 'Import in progress...'

      @importStackTemplate repo, (err, stackData) =>

        @loader.hide()

        if err
          @outputView.add 'Import failed:', err
          @actionButton.hide()
          return

        @outputView.add 'Import successful!', stackData

        @loader.show()
        @outputView.add 'Creating stack for provided data...'

        @createStackTemplate stackData, (err, stack) =>

          if err
            @outputView.add 'Stack create failed:', err
            @actionButton.hide()

          else
            @loader.hide()
            @outputView.add 'Stack created:', stack
            @outputView.add 'You can now open editor for imported stack template.'

            @actionButton.setTitle 'Open Editor'
            @actionButton.setCallback ->
              router.handleRoute "/Stack-Editor/#{stack._id}"

            @actionButton.show()

            @getDelegate().scrollToBottom()


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
