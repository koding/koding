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

    gitlabUrl = 'gitlabUrl-here'

    @message = new kd.CustomHTMLView
      tagName: 'p'
      partial: """
        This tool is intended to use with GitLab integration which is enabled
        for this team on <b>#{gitlabUrl}</b>. You can use action endpoints
        provided in your GitLab service to be able to use this tool to try
        your projects.
      """

    @loader = new kd.LoaderView
      size       :
        width    : 22
        height   : 22

    @outputView = new OutputView
      delegate: @getDelegate()
      cssClass: 'hidden'
      separator: '  '

    @actionButton = new kd.ButtonView
      cssClass : 'GenericButton HomeAppView-Stacks--actionButton'
      title: 'Open GitLab'
      callback: ->
        window.open gitlabUrl, '_blank'


  handleQuery: (query = {}) ->

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


  pistachio: ->

    '''
    <h2>Stack Importer</h2>
    {{> @message}}
    {{> @loader}}
    {{> @outputView}}
    {{> @actionButton}}
    '''