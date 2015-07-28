kd             = require 'kd'
InitialView    = require './stacksv2/initialview'


module.exports = class GroupStackSettingsV2 extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'stacks'
    super options, data


  viewAppended: ->
    @addSubView new InitialView


  setGroupTemplate: (stackTemplate) ->

    { computeController, groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return @showError err  if err

      new kd.NotificationView
        title : "Group (#{slug}) stack has been saved!"
        type  : 'mini'

      computeController.createDefaultStack yes
      computeController.checkStackRevisions()
