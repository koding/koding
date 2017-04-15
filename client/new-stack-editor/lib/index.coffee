debug = (require 'debug') 'nse'

kd = require 'kd'
async = require 'async'
AppController = require 'app/appcontroller'
showError = require 'app/util/showError'

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

    { editor, logs, stack, credentials, variables } = @stackEditor.controllers

    currentTemplate = @stackEditor.getData()
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

      (next) ->
        logs.add 'checking stack...'
        stack.check next

      (next) ->
        logs.add 'generating stack...'
        stack.save next

    ]

    async.series queue, (err, result) =>

      @stackEditor.setBusy no

      debug 'initializeStack result', err, result

      if err
        logs.handleError err
      else
        [ ..., updatedTemplate, generatedStack ] = result
        logs.add 'stack template updated successfully'
        debug 'updated template instance', updatedTemplate
        debug 'generated stack', generatedStack


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

    onClose = ->
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

    handleDeleteMachine = ({ operation, value }) ->
      if value is machineId and operation is 'pop'
        storage.off 'change:machines', handleDeleteMachine
        do onClose

    storage.on 'change:machines', handleDeleteMachine

    @builds[templateId] = modal

    return


  hideBuildFlow: ->

    builder.hide()  for templateId, builder of @builds
