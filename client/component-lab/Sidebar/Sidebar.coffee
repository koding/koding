_ = require 'lodash'
kd = require 'kd'
React = require 'react'
SidebarMachine = require 'lab/SidebarMachine'
SidebarNoStacks = require 'app/components/sidebarstacksection/sidebarnostacks'
SidebarManagedVMs = require 'lab/SidebarManagedVMs'
SidebarStackSection = require 'lab/SidebarStackSection'
SidebarStackHeaderSection = require 'app/components/sidebarstacksection/sidebarstackheadersection'


module.exports = class Sidebar extends React.Component

  @propTypes =
    stacks: React.PropTypes.object
    stacksWithMachines: React.PropTypes.object
    stacksWithTemplates: React.PropTypes.object
    stacksWithMenuItems: React.PropTypes.object
    draftStackTemplates: React.PropTypes.array
    teamStacks: React.PropTypes.any
    privateStacks: React.PropTypes.any
    stackTemplates: React.PropTypes.any
    sharedVMs: React.PropTypes.array
    reinitStack: React.PropTypes.func
    destroyStack: React.PropTypes.func
    handleRoute: React.PropTypes.func
    openOnGitlab: React.PropTypes.func
    initializeStack: React.PropTypes.func

  @defaultProps =
    stacks: {}
    stacksWithMachines: {}
    stacksWithTemplates: {}
    stacksWithMenuItems: {}
    draftStackTemplates: []
    teamStacks: []
    privateStacks: []
    stackTemplates: []
    sharedVMs: []
    reinitStack: kd.noop
    destroyStack: kd.noop
    handleRoute: kd.noop
    openOnGitlab: kd.noop
    initializeStack: kd.noop

  PREVIEW_COUNT = 10

  renderStack: (stack) ->

    machines = @props.stacksWithMachines[stack._id] or []
    template = @props.stacksWithTemplates[stack._id] or {}
    menuItems = @props.stacksWithMenuItems[stack._id] or {}

    <SidebarStackSection
      key={stack._id}
      stack={stack}
      template={template}
      machines={machines}
      menuItems={menuItems}
      reinitStack={@props.reinitStack}
      destroyStack={@props.destroyStack}
      initializeStack={@props.initializeStack}
      handleRoute={@props.handleRoute}
      openOnGitlab={@props.openOnGitlab} />


  renderPrivateStacks: ->

    @props.privateStacks.map (stack) => @renderStack stack


  renderTeamStacks: ->

    @props.teamStacks.map (stack) => @renderStack stack


  renderStacks : ->

    if Object.keys(@props.stacks).length
      <SidebarStackHeaderSection>
        {@renderTeamStacks()}
        {@renderPrivateStacks()}
      </SidebarStackHeaderSection>
    else
      <SidebarNoStacks />


  renderDrafts: ->

    return  unless @props.draftStackTemplates

    @props.draftStackTemplates.map (draftStackTemplate) =>
      @renderStack draftStackTemplate


  renderSharedVMs: ->

    return unless @props.sharedVMs.length
    # change it SidebarSharedVMs
    <SidebarManagedVMs  machines={@props.sharedVMs} />


  renderStackTemplates: ->

    return unless @props.stackTemplates

    _.values(@props.stackTemplates).map (template) =>
      @renderStack template

  render: ->

    <div className='Sidebar-section-wrapper'>
      {@renderStacks()}
      {@renderDrafts()}
      {@renderSharedVMs()}
    </div>
