kd = require 'kd'
Machine = require 'app/providers/machine'
BuildStackPageView = require '../views/buildstackpageview'
helpers = require '../helpers'
showError = require 'app/util/showError'

module.exports = class BuildStackController extends kd.Controller

  { Running } = Machine.State

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    stack = @getData()
    { container } = @getOptions()

    container.addSubView @buildStackPage = new BuildStackPageView
      stackName : stack.title
    @buildStackPage.hide()


  updateProgress: (percentage, message = '') ->

    @buildStackPage.updatePercentage percentage  if percentage?

    message = message.replace 'machine', 'VM'
    message = message.capitalize()
    @buildStackPage.setStatusText message

  completeProcess: ->

    @buildStackPage.updatePercentage 100


  show: ->

    @buildStackPage.show()
