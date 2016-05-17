kd = require 'kd'
Machine = require 'app/providers/machine'
BasePageController = require './basepagecontroller'
BuildStackPageView = require '../views/buildstackpageview'
BuildStackErrorPageView = require '../views/buildstackerrorpageview'
showError = require 'app/util/showError'

module.exports = class BuildStackController extends BasePageController

  { Running } = Machine.State

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    stack = @getData()

    @buildStackPage = new BuildStackPageView stackName : stack.title
    @errorPage = new BuildStackErrorPageView()
    @registerPages [ @buildStackPage, @errorPage ]

    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @updateProgress() # reset previous values
      @emit 'RebuildRequested'


  updateProgress: (percentage, message = '') ->

    @buildStackPage.updatePercentage percentage

    message = message.replace 'machine', 'VM'
    message = message.capitalize()
    @buildStackPage.setStatusText message


  completeProcess: ->

    @buildStackPage.updatePercentage 100


  showError: (err) ->

    @setCurrentPage @errorPage
    @errorPage.setError err
