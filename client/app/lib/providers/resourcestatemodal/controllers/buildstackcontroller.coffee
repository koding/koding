kd = require 'kd'
Machine = require 'app/providers/machine'
BasePageController = require './basepagecontroller'
BuildStackPageView = require '../views/buildstackpageview'
BuildStackErrorPageView = require '../views/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/buildstacksuccesspageview'
showError = require 'app/util/showError'

module.exports = class BuildStackController extends BasePageController

  { Running } = Machine.State

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    stack = @getData()

    @buildStackPage = new BuildStackPageView { stackName : stack.title }
    @errorPage = new BuildStackErrorPageView()
    @successPage = new BuildStackSuccessPageView()
    @registerPages [ @buildStackPage, @errorPage, @successPage ]

    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @updateProgress() # reset previous values
      @emit 'RebuildRequested'
    @forwardEvent @successPage, 'ClosingRequested'


  updateProgress: (percentage, message = '') ->

    @buildStackPage.updatePercentage percentage

    message = message.capitalize()
    @buildStackPage.setStatusText message


  completeProcess: ->

    @buildStackPage.updatePercentage 100
    kd.utils.wait 100, @lazyBound 'setCurrentPage', @successPage


  showError: (err) ->

    @setCurrentPage @errorPage
    @errorPage.setError err
