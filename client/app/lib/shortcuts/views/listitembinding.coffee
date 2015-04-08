kd = require 'kd'
_  = require 'lodash'
present = require '../presenters/binding'

module.exports =

class ShortcutsListItemBinding extends kd.View

  constructor: (options, @model) ->

    super _.extend cssClass: 'col'


  viewAppended: ->

    @addSubView new kd.View
      cssClass : 'keys'
      partial  : present _.first @model.binding,
