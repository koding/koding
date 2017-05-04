debug = require('debug')('stack-editor:routehandler')
kd = require 'kd'
lazyrouter = require 'app/lazyrouter'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'

module.exports = -> lazyrouter.bind 'stackeditor', (type, info, state, path, ctx) ->

  debug 'routing', { type, info, state, path }

  unless canCreateStacks() or type is 'edit-stack'
    new kd.NotificationView { title: 'You are not allowed to create/edit stacks!' }
    return kd.singletons.router.back()

  if type in ['home', 'new']
    kd.singletons.appManager.tell 'Stackeditor', 'openStackWizard'
  else
    kd.singletons.appManager.open 'Stackeditor', (app) ->
      { templateId, stackId } = info.params
      debug 'opening stack editor', { templateId, stackId }
      app.openEditor templateId, stackId
