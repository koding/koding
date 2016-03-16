kd    = require 'kd'
JView = require '../../jview'

module.exports = class TeamName extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'team-name'
    options.tagName  = 'span'

    super options, data

    { groupsController } = kd.singletons

    groupsController.ready =>
      @setData groupsController.getCurrentGroup()


  pistachio: -> '{{ #(title)}}'
