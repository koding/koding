kd                 = require 'kd'
remote             = require('app/remote').getInstance()
StacksCustomViews  = require './stacks/stackscustomviews'


module.exports     = class GroupStackSettings extends kd.View

  StacksCustomViews.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'stacks'
    super options, data


  viewAppended: ->
    @initiateInitialView()


  initiateInitialView: ->
    @replaceViewsWith
      initialView: @bound 'initiateNewStackWizard'


  initiateNewStackWizard: (stackTemplate) ->

    NEW_STACK_STEPS = [
      'stepSelectProvider'
      'stepSetupCredentials'
      'stepBootstrap'
      'stepDefineStack'
      'stepComplete'
    ]

    steps = []

    NEW_STACK_STEPS.forEach (step, index) =>
      steps.push (data) =>
        @replaceViewsWith "#{step}": {
          callback       : steps[index+1] or @bound 'setGroupTemplate'
          cancelCallback : steps[index-1] or @bound 'initiateInitialView'
          data
        }

    steps.first { stackTemplate }


  setGroupTemplate: (stackTemplate) ->

    { groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    @replaceViewsWith loader: 'Setting group stack...'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return @showError err  if err

      new kd.NotificationView
        title : "Group (#{slug}) stack has been saved!"
        type  : 'mini'

      @initiateInitialView()
