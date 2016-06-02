kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

DisabledMembersStacks = require './components/disabledmemberslist'


module.exports = class HomeStacksDisabledMembersStacks extends ReactView

  onOpenItem: -> @getDelegate().emit 'ModalDestroyRequested', yes

  renderReact: ->
    <DisabledMembersStacks.Container onOpenItem={@bound 'onOpenItem'} />


