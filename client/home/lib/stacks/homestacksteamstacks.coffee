kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

TeamStackList = require './components/teamstackslist'


module.exports = class HomeStacksTeamStacks extends ReactView

  onOpenItem: -> @getDelegate().emit 'ModalDestroyRequested', yes


  renderReact: ->
    <TeamStackList.Container onOpenItem={@bound 'onOpenItem'} />
