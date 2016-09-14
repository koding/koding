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
    sidebarStacks: React.PropTypes.any
    stacksAndCredential: React.PropTypes.any
    stacksAndMachines: React.PropTypes.any
    stacksAndMenuItems: React.PropTypes.any
    stacksAndTemplates: React.PropTypes.any
    sharedVMs: React.PropTypes.array
    reinitStack: React.PropTypes.func
    destroyStack: React.PropTypes.func
    handleRoute: React.PropTypes.func
    openOnGitlab: React.PropTypes.func
    initializeStack: React.PropTypes.func

  @defaultProps =
    sidebarStacks: {}
    stacksAndCredential: {}
    stacksAndMachines: {}
    stacksAndMenuItems: {}
    stacksAndTemplates: {}
    sharedVMs: []
    reinitStack: kd.noop
    destroyStack: kd.noop
    handleRoute: kd.noop
    openOnGitlab: kd.noop
    initializeStack: kd.noop

  PREVIEW_COUNT = 10

  renderStack: (stack) ->

    machines = @props.stacksAndMachines?[stack._id] or []
    template = @props.stacksAndTemplates?[stack._id] or {}
    menuItems = @props.stacksAndMenuItems?[stack._id] or {}
    credential = @props.stacksAndCredential?[stack._id] or {}

    <SidebarStackSection
      key={stack._id}
      stack={stack}
      template={template}
      machines={machines}
      menuItems={menuItems}
      credential={credential}
      reinitStack={@props.reinitStack}
      destroyStack={@props.destroyStack}
      initializeStack={@props.initializeStack}
      handleRoute={@props.handleRoute}
      openOnGitlab={@props.openOnGitlab} />


  renderStacks : ->

    if Object.keys(@props.sidebarStacks).length
      <SidebarStackHeaderSection>
        {@renderSidebarStacks()}
      </SidebarStackHeaderSection>
    else
      <SidebarNoStacks />

  renderSidebarStacks: ->

    _.values(@props.sidebarStacks).map (stack) =>
      @renderStack stack


  renderSharedVMs: ->

    return unless @props.sharedVMs.length
    # change it SidebarSharedVMs
    <SidebarManagedVMs  machines={@props.sharedVMs} />


  render: ->

    <div className='Sidebar-section-wrapper'>
      {@renderStacks()}
      {@renderSharedVMs()}
    </div>
