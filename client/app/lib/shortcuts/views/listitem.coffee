kd = require 'kd'
_  = require 'lodash'
BindingView = require './listitembinding.coffee'

module.exports =

class ShortcutsListItem extends kd.ListItemView

  constructor: (options={}, @model) ->

    super options


  viewAppended: ->

    toggleButton = new kd.ToggleButton
      cssClass: 'topic-follow-btn'
      defaultState: 'Enabled'
      loader:
        color: '#7d7d7d'
      icon: yes

      states: [
        title: 'Enabled'
        cssClass: 'enabled'
        callback: ->
      ,
        title: 'Disabled'
        cssClass: 'disabled'
        callback: ->
      ]

    toggleView = new kd.View cssClass: 'col'

    toggleView.addSubView toggleButton

    @addSubView toggleView

    @addSubView new kd.View
      cssClass : 'col'
      partial  : _.escape @model.description

    @addSubView new BindingView null, @model
