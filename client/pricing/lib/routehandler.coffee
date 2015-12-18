kd          = require 'kd'
lazyrouter  = require 'app/lazyrouter'


module.exports = ->

  lazyrouter.bind 'pricing', (type, info, state, path, ctx) ->

    { appManager } = kd.singletons

    switch type
      when 'home'
        appManager.open 'Pricing'

      when 'teams', 'individuals'
        appManager.open 'Pricing', (app) ->
          app.getView().switchBranch type
