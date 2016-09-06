kd = require 'kd'
React = require 'react'
immutable = require 'app/util/immutable'
Immutable = require 'seamless-immutable'
SidebarMachine = require 'lab/SidebarMachine'
MENU = null


module.exports = class SidebarStackSection extends React.Component

  @propTypes =
    stack: React.PropTypes.object
    menuItems: React.PropTypes.object
    updated: React.PropTypes.bool
    machines: React.PropTypes.array
    handleRoute: React.PropTypes.func
    openOnGitlab: React.PropTypes.func
    initializeStack: React.PropTypes.func
    reinitStack: React.PropTypes.func


  @defaultProps =
    stack : {}
    menuItems: {}
    updated: no
    machines: []
    handleRoute: kd.noop
    openOnGitlab: kd.noop
    initializeStack: kd.noop
    reinitStack: kd.noop


  showMenuItems: (event) ->

    kd.utils.stopDOMEvent event

    { stack } = @props

    callback = (item, event) =>
      if stack.baseStackId or stack.title is 'Managed VMs'
      then @onMenuItemClick item, event
      else @onMenuDraftItemClick item, event

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: 102 + 31 }
    Object.keys(@props.menuItems).map (item) =>

      @props.menuItems[item] = { callback }

    MENU = new kd.ContextMenu menuOptions, @props.menuItems


  onMenuDraftItemClick: (item, event) ->

    MENU.destroy()
    { stack, template } = @props
    { title } = item.getData()
    switch title
      when 'Edit' then @props.handleRoute "/Stack-Editor/#{stack._id}"
      when 'Initialize'
        @props.initializeStack template
      when 'Open on GitLab'
        @props.openOnGitlab stack


  onMenuItemClick: (item, event) ->

    MENU.destroy()

    { stack, template, machines } = @props
    { title } = item.getData()

    templateId = stack.baseStackId
    #check for template or stack then get id or baseStackId

    switch title
      when 'Edit' then @props.handleRoute "/Stack-Editor/#{template._id}"
      when 'Reinitialize', 'Update'
        @props.reinitStack stack, machines, template
      when 'Destroy VMs' then @props.destroyStack stack, machines
      when 'VMs'
        @props.handleRoute '/Home/Stacks/virtual-machines'
      when 'Open on GitLab' then @props.openOnGitlab stack


  renderUpdateIcon: ->

    return  unless @props.updated


  renderMachines: ->

    @props.machines.map (machine) ->
      <SidebarMachine key={machine._id} machine={machine}/>


  render: ->

    <div className='SidebarStackSection'>
      {@renderUpdateIcon()}
      <div className='SidebarStackSection--title' onClick={@showMenuItems.bind(this)}>
        {@props.stack.title}
      </div>
      {@renderMachines()}
    </div>
