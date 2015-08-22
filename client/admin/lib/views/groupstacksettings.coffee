kd                 = require 'kd'
curryIn            = require 'app/util/curryIn'
InitialView        = require './stacks/initialview'
DefineStackTabView = require './stacks/definestacktabview'


module.exports = class GroupStackSettings extends kd.View


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

    defineStackTabView = @addSubView new DefineStackTabView {}, { stackTemplate }

    defineStackTabView.on 'Reload', => @initialView.reload()

    defineStackTabView.on ['Cancel', 'Completed'], =>
      @initialView.show()
      defineStackTabView.destroy()

