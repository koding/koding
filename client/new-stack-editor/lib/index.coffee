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

    @mainView.addSubView @stackEditor = new StackEditor { cssClass: 'initial' }

    @stackEditor.on Events.InitializeRequested, @bound 'initializeStack'


  openEditor: (templateId, stackId, options = {}, callback = kd.noop) ->

    { reset = no, build = no } = options

    unless templateId
      do @openStackWizard
      return callback { message: 'No template provided' }

    @fetchStackTemplate templateId, reset, (err, template) =>

      @stackEditor.unsetClass 'initial'

      if err
        showError err
        return callback err

      @stackEditor.setData template, reset
      @triggerBuild template  if build

      callback null

    markAsLoaded templateId, stackId


  openStackWizard: (handleRoute = yes) ->

    new StackWizardModal { handleRoute }
    markAsLoaded()


  reloadEditor: (templateId, stackId) ->

    @openEditor templateId, stackId, { reset: yes }


  fetchStackTemplate: (templateId, reset = no, callback) ->

    { storage } = kd.singletons.computeController

    if not reset and template = storage.templates.get templateId
      return callback null, template

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
          @openEditor templateId, null, {}, next
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


  triggerBuild: (template) ->

    { storage } = kd.singletons.computeController
    machine = storage.machines.get 'generatedFrom.templateId', template.getId()

    debug 'build triggered for', { machine, template }

    modalOptions = {
      state: 'NotInitialized'
      container: @getView()
      initial: yes
    }

    modal = new ResourceStateModal modalOptions, machine
    modal.once 'KDObjectWillBeDestroyed', -> modal = null
    modal.once 'IDEBecameReady', -> console.log 'IDEBecameReady ....'

    return
