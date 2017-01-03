kd = require 'kd'
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

  @options     =
    name       : 'Stackeditor'
    customName : 'new-stack-editor'
    behavior   : 'application'

  constructor: (options = {}, data) ->

    super options, data

    @templates = {}
    @mainView.addSubView @stackEditor = new StackEditor

    @stackEditor.on Events.InitializeRequested, @bound 'initializeStack'


  openEditor: (templateId, reset = no) ->

    @fetchStackTemplate templateId, (err, template) =>
      return showErrorNotification err  if err
      @stackEditor.setTemplateData template, reset

    markAsLoaded templateId


  openStackWizard: (handleRoute = yes) ->

    new StackWizardModal { handleRoute }
    markAsLoaded()


  reloadEditor: (templateId) ->

    delete @templates[templateId]
    @openEditor templateId, reset = yes


  fetchStackTemplate: (templateId, callback) ->

    if template = @templates[templateId]
      return callback null, template

    cc = kd.singletons.computeController
    cc.fetchStackTemplate templateId, (err, template) =>
      return callback err  if err
      return callback Errors.NotExists  unless template

      callback null, @templates[templateId] = template


  initializeStack: (template) ->

    console.trace()
    log '::initializeStack', template


  createStackTemplate: (provider) ->

    unless provider
      return console.warn 'Provider is required!'

    EnvironmentFlux.actions.createStackTemplateWithDefaults provider
      .then ({ stackTemplate }) ->
        kd.singletons.router.handleRoute "/Stack-Editor/#{stackTemplate._id}"
