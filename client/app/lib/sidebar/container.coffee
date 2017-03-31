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


calculateOwnedResources = (props, state) ->

  debug 'start calculating own resources', { props, state }

  # first get the stacks created from individual templates
  # we are gonna have an array like this:
  resources = props.templates.map (template) ->
    stacks = props.stacks.filter (stack) -> stack.baseStackId is template.getId()

    # FIXME: find a way to inject unreadCounts here. ~Umut
    if stacks.length
    then stacks.map (stack) -> { stack, template, unreadCount: 0 }
    else [{ stack: null, template, unreadCount: 0 }]

  debug 'resources are calculated before flatten', resources

  # now let's flatten them to have a single array
  resources = flatten(resources).sort ({ stack }) -> if stack then -1 else 1

  [ managedStack ] = props.stacks.filter (s) -> s.title.indexOf('Managed VMs') > -1

  if managedStack
    resources.push { stack: managedStack, template: null, unreadCount: 0 }

  debug 'owned resources are calculated', resources

  return resources


calculateSharedResources = (props, state) ->

  debug 'start calculating shared resources', { props, state }

  resources =
    permanent: props.machines.filter (m) -> m.getType() is 'shared'
    collaboration: props.machines.filter (m) -> m.getType() is 'collaboration'

  debug 'shared resources are calculated', resources

  return resources


module.exports = class SidebarContainer extends React.Component

  constructor: (props) ->
    super props

    @state =
      ownedResources: calculateOwnedResources @props
      sharedResources: calculateSharedResources @props


  componentDidMount: ->

    { computeController, mainController } = kd.singletons

    SidebarFlux.actions.loadVisibilityFilters().then ->
      mainController.ready ->
        computeController.fetchStackTemplates kd.noop


  componentWillReceiveProps: (nextProps, nextState) ->

    @setState
      ownedResources: calculateOwnedResources nextProps, nextState
      sharedResources: calculateSharedResources nextProps, nextState


  render: ->

    { curry } = kd.utils

    <Scroller className={curry 'activity-sidebar', @props.className}>

      <SidebarResources
        disabled={isGroupDisabled()}
        owned={@state.ownedResources}
        shared={@state.sharedResources} />

      <SidebarFooterLogo
        src={DEFAULT_LOGOPATH} />

    </Scroller>
