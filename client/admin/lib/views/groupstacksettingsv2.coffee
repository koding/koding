kd              = require 'kd'
curryIn         = require 'app/util/curryIn'

InitialView     = require './stacksv2/initialview'
DefineStackView = require './stacksv2/definestackview'


module.exports = class GroupStackSettingsV2 extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks stacks-v2'

    super options, data


  viewAppended: ->

    @addSubView initialView = new InitialView

    initialView.on ['CreateNewStack', 'EditStack'], (stackTemplate) =>

      initialView.hide()

      requiresReload  = !stackTemplate?
      defineStackView = @addSubView new DefineStackView {}, { stackTemplate }

      defineStackView.on ['Cancel', 'Completed'], (stackTemplate) ->
        initialView.reload()  if requiresReload
        initialView.show()
        @destroy()


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
