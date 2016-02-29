kd = require 'kd'
getGroup = require 'app/util/getGroup'

module.exports = ->

  registerRoutes 'Members',
    "/:name?/Members" : ({params, query}) ->
      {appManager} = kd.singletons
      kd.getSingleton('groupsController').ready ->
        group = getGroup()
        kd.getSingleton("appManager").tell 'Members', 'createContentDisplay', group, (contentDisplay) ->
          contentDisplay.emit "handleQuery", {filter: "members"}
