kd = require 'kd'
{ markAsLoaded, log } = require './helpers'
AppController = require 'app/appcontroller'

do require './routehandler'

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
    behavior   : 'application'

  constructor: (options = {}, data) ->

    console.trace()
    log '::init', options, data

    super options, data


  openEditor: (stackTemplateId) ->

    console.trace()
    log '::openEditor', stackTemplateId

    markAsLoaded stackTemplateId


  openStackWizard: (handleRoute = yes) ->

    console.trace()
    log '::openStackWizard', handleRoute

    markAsLoaded null


  reloadEditor: (templateId, skipDataUpdate) ->

    console.trace()
    log '::reloadEditor', templateId, skipDataUpdate

