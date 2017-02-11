debug = (require 'debug') 'nse'

kd = require 'kd'
async = require 'async'
AppController = require 'app/appcontroller'
showErrorNotification = require 'app/util/showErrorNotification'

EnvironmentFlux = require 'app/flux/environment'

Events = require './events'
StackEditor = require './views'
StackWizardModal = require './views/wizard/stackwizardmodal'

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

    @templates = {}
    @mainView.addSubView @stackEditor = new StackEditor

    @stackEditor.on Events.InitializeRequested, @bound 'initializeStack'


  openEditor: (templateId, options = {}, callback = kd.noop) ->

    { reset = no } = options

    unless templateId
      do @openStackWizard
      return callback { message: 'No template provided' }

    @fetchStackTemplate templateId, (err, template) =>

      if err
        showErrorNotification err
        return callback err

      @stackEditor.setTemplateData template, reset
      callback null

    markAsLoaded templateId


  openStackWizard: (handleRoute = yes) ->

    new StackWizardModal { handleRoute }
    markAsLoaded()


  reloadEditor: (templateId) ->

    return  unless @templates[templateId]

    delete @templates[templateId]
    @openEditor templateId, { reset: yes }


  fetchStackTemplate: (templateId, callback) ->

    if template = @templates[templateId]
      return callback null, template

    cc = kd.singletons.computeController
    cc.fetchStackTemplate templateId, (err, template) =>
      return callback err  if err
      return callback Errors.NotExists  unless template

      callback null, @templates[templateId] = template


  initializeStack: (templateId) ->

    debug 'initializeStack called for', templateId

    { controllers: { logs, credentials, variables } } = @stackEditor
    currentTemplate = @stackEditor.getData()

    logs.add 'updating stack template...'

    queue = [

      (next) =>
        if @stackEditor.getData()._id isnt templateId
          logs.add 'loading template first...'
          @openEditor templateId, {}, next
        else
          next()

      (next) =>
        logs.add 'checking template...'
        @stackEditor.check next

      (next) ->
        logs.add 'checking credentials...'
        credentials.check next

      (next) ->
        logs.add 'saving variables...'
        variables.save next

      (next) ->
        logs.add 'saving credentials...'
        credentials.save next

      (next) =>
        logs.add 'saving template...'
        @stackEditor.save next

    ]

    async.series queue, (err, result) ->

      debug 'initializeStack result', err, result

      if err
        logs.handleError err
      else
        [ ..., updatedTemplate ] = result
        logs.add 'stack template updated successfully'
        debug 'updated template instance', updatedTemplate


  createStackTemplate: (provider) ->

    unless provider
      return console.warn 'Provider is required!'

    EnvironmentFlux.actions.createStackTemplateWithDefaults provider
      .then ({ stackTemplate }) ->
        kd.singletons.router.handleRoute "/Stack-Editor/#{stackTemplate._id}"
