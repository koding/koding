kd = require 'kd'
lazyrouter = require 'app/lazyrouter'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'

module.exports = -> lazyrouter.bind 'stackeditor', (type, info, state, path, ctx) ->

  unless canCreateStacks()
    new kd.NotificationView { title: 'You are not allowed to create/edit stacks!' }
    return kd.singletons.router.back()

  kd.singletons.appManager.open 'Stackeditor', (app) ->

    switch type
      when 'home', 'new' then app.openStackWizard()
      when 'edit-stack' then app.openEditor info.params.stackTemplateId
