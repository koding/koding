kd = require 'kd'
Encoder = require 'htmlencode'
EnvironmentFlux = require 'app/flux/environment'

remote = require 'app/remote'
showError = require 'app/util/showError'
OutputView = require 'stack-editor/editor/outputview'

parseQuery = (query) ->

  { repo, branch, sha } = query

  repo = Encoder.XSSEncode repo

  if branch
    branch = Encoder.XSSEncode branch
    repo = "#{repo}/#{branch}"  if branch

  return { repo, commitId: sha, branch }


module.exports = class HomeStacksImport extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView-Stacks--import'

    super options, data


  viewAppended: ->

    @addSubView new kd.CustomHTMLView
      tagName: 'h2'
      partial: 'Stack Importer'

    @addSubView @loader = new kd.LoaderView
      showLoader : yes
      size       :
        width    : 22
        height   : 22

    @addSubView @message = new kd.CustomHTMLView
      tagName: 'p'
      partial: 'Loading...'

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

      @actionButton.show()
      @actionButton.setTitle 'Open GitLab'
      @actionButton.setCallback ->
        kd.singletons.linkController.openOrFocus host

      @message.updatePartial """
        This tool is intended to be used with GitLab. The integration is
        enabled for this team at <a href="#{host}">#{host}</a>. To be able to
        run your projects on Koding, please use action endpoints provided in
        your GitLab service.
      """

      @emit 'ready'


  handleQuery: (query = {}) -> @ready =>

    { repo, commitId } = parseQuery query

    @message.hide()
    @actionButton.hide()

    @outputView.show()
    @outputView.add 'Got repo as follow:', repo

    { computeController, groupsController, router } = kd.singletons

    if commitId
      @outputView.add 'Checking existing VM for given commit id:', commitId
      if machine = computeController.findMachineFromRemoteData { commitId }
        @outputView.add "Found VM: #{machine.label} redirecting..."
        kd.utils.wait 2000, ->
          router.handleRoute "/IDE/#{machine.slug}"
        return

      @outputView.add "Couldn't find any VM, processing request..."

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
            @outputView.add 'Launching editor for imported stack template...'

            launchEditor = -> router.handleRoute "/Stack-Editor/#{stack._id}"
            kd.utils.wait 2000, launchEditor

            @actionButton.setTitle 'Launch Editor Now'
            @actionButton.setCallback launchEditor

            @actionButton.show()

            @getDelegate().scrollToBottom()


  importStackTemplate: (repo, callback) ->

    { GitProvider } = remote.api
    GitProvider.importStackTemplateData {
      provider: 'gitlab'
      repo
    }, callback


  createStackTemplate: (stackData, callback) ->

    { GitProvider } = remote.api
    GitProvider.createImportedStackTemplate null, stackData, (err, stack) ->

      unless err
        EnvironmentFlux.actions.loadStackTemplates()

      callback err, stack
