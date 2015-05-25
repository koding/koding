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

    @replaceViewsWith loader: 'main-loader'
    @fetchData (err, data) =>
      if err? or not data?.stackTemplate
      then @replaceViewsWith noStackFoundView: @bound 'initiateNewStackWizard'
      else @replaceViewsWith stacksView: data


  initiateNewStackWizard: ->

    NEW_STACK_STEPS = [
      'stepSelectProvider'
      'stepSetupCredentials'
      'stepBootstrap'
      'stepDefineStack'
      'stepTestAndSave'
    ]

    steps = []

    NEW_STACK_STEPS.forEach (step, index) =>
      steps.push (data) =>
        @replaceViewsWith "#{step}": {
          callback: steps[index+1] or -> console.log 'LAST ONE'
          cancelCallback: steps[index-1] or @bound 'initiateInitialView'
          data
        }

    steps.first()


  fetchData: (callback) ->

    { groupsController }            = kd.singletons
    { JCredential, JStackTemplate } = remote.api

    JCredential.some {}, { limit: 30 }, (err, credentials) ->

      return callback {message: 'Failed to fetch credentials:', err}  if err

      currentGroup = groupsController.getCurrentGroup()

      if not currentGroup.stackTemplates?.length > 0
        callback null, {credentials}
        return

      {stackTemplates} = currentGroup
      stackTemplateId  = stackTemplates.first # TODO support multiple templates

      JStackTemplate.some
        _id   : stackTemplateId
      , limit : 1
      , (err, stackTemplates) ->

          if err
            console.warn 'Failed to fetch stack template:', err
            callback null, {credentials}
          else
            stackTemplate = stackTemplates.first
            callback null, {credentials, stackTemplate}


  setGroupTemplate: (stackTemplate) ->

    { groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return @showError err  if err

      new kd.NotificationView
        title: "Group (#{slug}) stack has been saved!"

