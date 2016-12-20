kd = require 'kd'
{ markAsLoaded, log } = require './helpers'
AppController = require 'app/appcontroller'
showErrorNotification = require 'app/util/showErrorNotification'
StackEditor = require './views'

do require './routehandler'

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

    console.trace()
    log '::init', options, data

    super options, data

    @templates = {}
    @mainView.addSubView @editor = new StackEditor


  openEditor: (templateId) ->

    console.trace()
    log '::openEditor', templateId

    @fetchStackTemplate templateId, (err, template) =>
      return showErrorNotification err  if err
      @editor.setTemplateData template

    markAsLoaded templateId


  openStackWizard: (handleRoute = yes) ->

    console.trace()
    log '::openStackWizard', handleRoute

    markAsLoaded null


  reloadEditor: (templateId, skipDataUpdate) ->

    console.trace()
    log '::reloadEditor', templateId, skipDataUpdate


  fetchStackTemplate: (templateId, callback) ->

    if template = @templates[templateId]
      return callback null, template

    cc = kd.singletons.computeController
    cc.fetchStackTemplate templateId, (err, template) =>
      return callback err  if err
      return callback Errors.NotExists  unless template

      callback null, @templates[templateId] = template
