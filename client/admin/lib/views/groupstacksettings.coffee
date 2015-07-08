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
      initialView: (selected) =>
        if selected is 'from-repo'
        then @initiateRepoFlowWizard()
        else @initiateNewStackWizard()


  initiateFollowing: (_steps, headers) ->

    steps = []

    _steps.forEach (step, index) =>
      steps.push (data) =>
        @replaceViewsWith "#{step}": {
          callback       : steps[index+1] or @bound 'setGroupTemplate'
          cancelCallback : steps[index-1] or @bound 'initiateInitialView'
          index          : index+1
          steps          : headers
          data
        }

    return steps


  initiateNewStackWizard: (stackTemplate) ->

    steps = @initiateFollowing [
      'stepSelectProvider'
      'stepSetupCredentials'
      'stepBootstrap'
      'stepDefineStack'
      'stepComplete'
    ], StacksCustomViews.STEPS.CUSTOM_STACK

    steps.first { stackTemplate }


  initiateRepoFlowWizard: (stackTemplate) ->

    steps = @initiateFollowing [
      'stepSelectRepo'
      'stepLocateFile'
      'stepFetchTemplate'
      'stepSetupCredentials'
      'stepBootstrap'
      'stepDefineStack'
      'stepComplete'
    ], StacksCustomViews.STEPS.REPO_FLOW

    steps.first { stackTemplate }


  setGroupTemplate: (stackTemplate) ->

    { groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    @replaceViewsWith mainLoader: 'Setting group stack...'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return @showError err  if err

      new kd.NotificationView
        title : "Group (#{slug}) stack has been saved!"
        type  : 'mini'

      @initiateInitialView()
