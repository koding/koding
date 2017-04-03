kd = require 'kd'
React = require 'app/react'
debug = require('debug')('sidebar:container')
{ flatten, sortBy } = require 'lodash'

{ DEFAULT_LOGOPATH } = require 'app/constants/common'

isGroupDisabled = require 'app/util/isGroupDisabled'

Scroller = require 'app/components/scroller'

SidebarFlux = require 'app/flux/sidebar'

SidebarResources = require './components/resources'
SidebarFooterLogo = require './components/footerlogo'

require './styl/sidebar.styl'
require './styl/sidebarmenu.styl'
require './styl/sidebarsection.styl'
require './styl/sidebarstacksection.styl'
require './styl/sidebarstackwidgets.styl'
require './styl/sidebarmachineslistItem.styl'
require './styl/sidebarwidget.styl'

calculateOwnedResources = require 'app/util/calculateOwnedResources'
calculateSharedResources = require 'app/util/calculateSharedResources'

module.exports = class SidebarContainer extends React.Component

  constructor: (props) ->
    super props

    @state =
      ownedResources: calculateOwnedResources @props
      sharedResources: calculateSharedResources @props
      loading: yes


  componentDidMount: ->

    { computeController, mainController } = kd.singletons

    SidebarFlux.actions.loadVisibilityFilters().then =>
      mainController.ready =>
        computeController.fetchStackTemplates =>
          @setState
            ownedResources: calculateOwnedResources @props, @state
            sharedResources: calculateSharedResources @props, @state
          , =>
            @setState { loading: no }


  componentWillReceiveProps: (nextProps, nextState) ->

    @setState
      ownedResources: calculateOwnedResources nextProps, nextState
      sharedResources: calculateSharedResources nextProps, nextState


  render: ->

    { curry } = kd.utils

    <Scroller className={curry 'activity-sidebar', @props.className}>

      {not @state.loading and
        <SidebarResources
          disabled={isGroupDisabled()}
          owned={@state.ownedResources}
          shared={@state.sharedResources} /> }

      <SidebarFooterLogo
        src={DEFAULT_LOGOPATH} />

    </Scroller>
