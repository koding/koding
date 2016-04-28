kd = require 'kd'
lazyrouter = require 'app/lazyrouter'


module.exports = -> lazyrouter.bind 'stackeditor', (type, info, state, path, ctx) ->

  kd.singletons.appManager.open 'Stackeditor', (app) ->

    switch type
      when 'home', 'new' then app.openStackWizard()
      when 'edit-stack' then app.openEditor info.params.stackTemplateId


