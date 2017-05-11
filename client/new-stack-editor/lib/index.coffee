debug = (require 'debug') 'nse'

kd = require 'kd'
async = require 'async'

isAdmin = require 'app/util/isAdmin'
showError = require 'app/util/showError'
canCreateStacks = require 'app/util/canCreateStacks'

AppController = require 'app/appcontroller'
EnvironmentFlux = require 'app/flux/environment'

Events = require './events'
StackEditor = require './views'
StackWizardModal = require './views/wizard/stackwizardmodal'
ResourceStateModal = require 'app/providers/resourcestatemodal'

{ markAsLoaded, log } = require './helpers'

do require './routehandler'

require 'new-stack-editor/styl'
# It will be moved to kd.js once it's ready ~ GG
require 'new-stack-editor/views/flexsplit/styl'

Errors      =
  NotExists :
    name    : 'NOT_EXISTS'
    message : 'Resource not found'

# Set cookie to enable new stack editor:
#
#  Cookies.set('use-nse', true, {path:'/'});
#
# And expire it to use current stack editor:
#
#  Cookies.expire('use-nse', {path:'/'});
#
module.exports = class StackEditorAppController extends AppController

  @options     = {
    name       : 'Stackeditor'
    customName : 'new-stack-editor'
    behavior   : 'application'
  }

  constructor: (options = {}, data) ->

    super options, data

    @builds = {}

    @mainView.addSubView @stackEditor = new StackEditor { cssClass: 'initial' }

    @stackEditor.on Events.InitializeRequested, @bound 'initializeStack'


  openEditor: (options = {}, callback = kd.noop) ->

    { reset = no, build = no,
      templateId, machineId } = options

    debug 'opening editor', options

    if not templateId and not machineId
      debug 'no information provided, opening stack wizard'
      do @openStackWizard
      return callback { message: 'No template provided' }

    markAsLoaded templateId  if templateId

    @hideBuildFlow()

    @fetchStackTemplate { templateId, machineId, reset }, (err, template) =>

      @stackEditor.unsetClass 'initial'

      if err
        showError err
        @openStackWizard()  if err is Errors.NotExists
        return callback err

      @stackEditor.setData template, reset
      @_setPermission template

      @showBuildFlow template, machineId  if build

      callback null


  openStackWizard: (handleRoute = yes) ->

    new StackWizardModal { handleRoute }
    markAsLoaded()


  reloadEditor: (templateId) ->

    @openEditor { templateId, reset: yes }


  fetchStackTemplate: (options, callback) ->

    debug 'fetchStackTemplate', options

    { templateId, machineId, reset } = options
    { storage } = kd.singletons.computeController

    if not reset and templateId and template = storage.templates.get templateId
      debug 'template found in cache', template
      return callback null, template

    if not templateId and machineId
      debug 'checking for machine'
      if machine = storage.machines.get machineId
        debug 'found the machine', machine
        templateId = machine.generatedFrom?.templateId
        debug 'got templateId from machine', templateId

    unless templateId
      debug 'templateId not found'
      return callback Errors.NotExists

    storage.templates.fetch templateId, null, reset

      .then (template) ->
        if template
          callback null, template
        else
          callback Errors.NotExists

        return template

      .catch (err) ->
        callback err


  initializeStack: (templateId) ->

    debug 'initializeStack called for', templateId

    currentTemplate = @stackEditor.getData()
    templateId ?= currentTemplate.getId()

    { editor, logs, stack, credentials, variables } = @stackEditor.controllers

    { computeController: cc } = kd.singletons
    hasGeneratedStack = !!(cc.findStackFromTemplateId templateId)
    debug 'has generated stack from this template?', hasGeneratedStack

    logs.add 'updating stack template...'

    @stackEditor.setBusy yes

    queue = [

      (next) =>
        if @stackEditor.getData()._id isnt templateId
          logs.add 'loading template first...'
          @openEditor { templateId }, next
        else
          next()

      (next) ->
        logs.add 'checking template...'
        editor.check next

      (next) ->
        logs.add 'checking credentials...'
        credentials.check next

      (next) ->
        logs.add 'saving variables...'
        variables.save next

      (next) ->
        logs.add 'saving credentials...'
        credentials.save next

      (next) ->
        logs.add 'saving template...'
        editor.save next

    ]

    async.series queue, (err, result) =>

      @stackEditor.setBusy no

      debug 'initializeStack result', err, result

      return logs.handleError err  if err

      [ ..., updatedTemplate ] = result
      logs.add 'template updateed successfully'
      debug 'updated template instance', updatedTemplate

      options = { template: updatedTemplate, hasGeneratedStack }

      cc.checkStackRevisions updatedTemplate._id, createIfNotFound = no

      @askForTeamDefault options, (err, generated) ->

        return  if generated

        logs.add 'generating stack...'
        stack.save (err, generatedStack) ->
          debug 'generated stack', generatedStack
          return  if logs.handleError err, ''

          logs.add 'stack generated successfully'

          { stack: { machines } } = generatedStack
          { router } = kd.singletons
          router.handleRoute "/Stack-Editor/Build/#{machines.first.getId()}"


  createStackTemplate: (provider) ->

    unless provider
      return console.warn 'Provider is required!'

    EnvironmentFlux.actions.createStackTemplateWithDefaults provider
      .then ({ stackTemplate }) ->
        kd.singletons.router.handleRoute "/Stack-Editor/#{stackTemplate._id}"


  showBuildFlow: (template, machineId) ->

    { computeController: { storage }, router } = kd.singletons

    templateId = template.getId()
    machine = storage.machines.get machineId

    debug 'build triggered for', { machine, template }

    if stackId = machine.getStackId?()
      debug 'mark as loaded', templateId, machine.getId()
      markAsLoaded templateId, stackId, machine.getId()

    if existingBuild = @builds[templateId]
      if existingBuild.getData().getId() is machineId
        return existingBuild.show()
      delete @builds[templateId]

    onClose = =>
      @_setPermission template
      router.handleRoute "/Stack-Editor/#{templateId}"

    if machine.isBuilt()
      return onClose()

    modalOptions = {
      state: 'NotInitialized'
      container: @getView()
      initial: yes
      onClose
    }

    modal = new ResourceStateModal modalOptions, machine
    modal.once 'KDObjectWillBeDestroyed', -> modal = null
    modal.once 'OperationCompleted', ->
      debug 'OperationCompleted', machineId

    modal.on 'shown', => @stackEditor.setReadOnly()

    handleDeleteMachine = ({ operation, value }) ->
      if value is machineId and operation is 'pop'
        storage.off 'change:machines', handleDeleteMachine
        do onClose

    storage.on 'change:machines', handleDeleteMachine

    @builds[templateId] = modal
    @stackEditor.setReadOnly()

    return


  hideBuildFlow: ->

    builder.hide()  for templateId, builder of @builds


  _setPermission: (template) ->

    @stackEditor.setReadOnly readonly = not (isAdmin() or template.isMine())

    if readonly

      message = 'You must be an admin to edit this stack.'
      if canCreateStacks()
        message += ' However, you can clone this stack.'
        action = {
          title : 'Clone'
          event : Events.Menu.Clone
        }
      else
        action = null

      @stackEditor.toolbar.setBanner {
        sticky  : yes
        message
        action
      }

    else
      @stackEditor.toolbar.setBanner { sticky: no }



  askForTeamDefault: (options, callback) ->

    # if user is not an admin this part is not necessary
    return callback null, generated = no  unless isAdmin()

    { logs } = @stackEditor.controllers
    { groupsController, computeController } = kd.singletons
    { template, hasGeneratedStack } = options

    # Find out if stackTemplate is already set as default for the team
    { stackTemplates }  = groupsController.getCurrentGroup()
    template.isDefault ?= template._id in (stackTemplates or [])
    hasGroupTemplates   = stackTemplates?.length

    if hasGeneratedStack

      # admin is editing a team stack
      if template.isDefault
        logs.add 'Setting as default team stack...'
        computeController.makeTeamDefault { template, force: yes }, (err) ->
          if err
            callback err
          else
            logs.add '''
              Your stack script is saved successfully and all your new team
              members now will see this stack by default. Existing users
              of the previous default-stack will be notified that
              default-stack has changed.
            '''
            callback null, generated = yes

      # admin is editing a private stack
      else
        logs.add '''
          If you want to auto-initialize this template when new users join
          your team, you need to select "Make Team Default" from the menu.
        '''
        callback null, generated = no

    else
      # admin is creating a new stack
      return callback null  if hasGroupTemplates

      logs.add 'Setting as default team stack...'
      computeController.makeTeamDefault { template }, (err) ->
        if err
          callback err
        else
          logs.add '''
            Your stack script is saved successfully and all your new team
            members now will see this stack by default. Existing users
            of the previous default-stack will be notified that default-stack
            has changed.
          '''
          callback null, generated = yes
