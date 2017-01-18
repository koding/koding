kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

DraftsList = require './components/draftslist'


module.exports = class HomeStacksDrafts extends ReactView

  onOpenItem: -> @getDelegate().emit 'ModalDestroyRequested', yes

  renderReact: ->
    <DraftsList.Container onOpenItem={@bound 'onOpenItem'} />
