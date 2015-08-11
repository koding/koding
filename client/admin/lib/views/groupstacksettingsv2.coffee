kd              = require 'kd'
curryIn         = require 'app/util/curryIn'

InitialView     = require './stacksv2/initialview'
DefineStackView = require './stacksv2/definestackview'


module.exports = class GroupStackSettingsV2 extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks stacks-v2'

    super options, data


  viewAppended: ->

    @initialView = @addSubView new InitialView

    @initialView.on [
      'NoTemplatesFound', 'CreateNewStack', 'EditStack'
    ], @bound 'showEditor'


  showEditor: (stackTemplate) ->

    @initialView.hide()

    defineStackView = @addSubView new DefineStackView {}, { stackTemplate }

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on ['Cancel', 'Completed'], =>
      @initialView.show()
      @destroy()

