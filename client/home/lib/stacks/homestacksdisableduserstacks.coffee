kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

DisabledUsersStacksList = require './components/disableduserstackslist'


module.exports = class HomeStacksDisabledUsers extends ReactView

  onOpenItem: -> @getDelegate().emit 'ModalDestroyRequested', yes


  renderReact: ->
    <DisabledUsersStacksList.Container onOpenItem={@bound 'onOpenItem'} />
