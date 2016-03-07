kd = require 'kd'

module.exports = class TeamName extends kd.CustomHTMLView

  constructor: (options = {}) ->

    { groupsController } = kd.singletons

    options.cssClass = 'team-name'
    options.tagName  = 'span'

    data = groupsController.getCurrentGroup()

    super options, data

    @setPartial data.title

    groupsController.ready =>

      group = groupsController.getCurrentGroup()
      group.on 'update', => @updatePartial group.title
