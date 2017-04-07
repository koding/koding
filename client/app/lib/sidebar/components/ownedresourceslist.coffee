debug = require('debug')('sidebar:ownedresourcelist')
kd = require 'kd'
cx = require 'classnames'
React = require 'app/react'

{ findDOMNode } = require 'react-dom'

whoami = require 'app/util/whoami'
isAdmin = require 'app/util/isAdmin'
canCreateStacks = require 'app/util/canCreateStacks'
isDefaultTeamStack = require 'app/util/isdefaultteamstack'
showError = require 'app/util/showError'

List = require 'app/components/list'
Link = require 'app/components/common/link'

SidebarMachineItem = require './machineitemcontainer'
OwnedResourceHeader = require './ownedresourceheader'
SidebarNoStacks = require './nostacks'

MENU = null

module.exports = class OwnedResourcesList extends React.Component

  constructor: (props) ->
    super props

    @headers = []


  onMenuItemClickError: (action, templateId) ->

    debug "error while #{action}", { templateId }

    showError "Error occured while #{action} the template"


  getSectionCount: -> @props.resources.length


  getRowCount: (sectionIndex) ->

    resource = @props.resources[sectionIndex]

    return resource.stack?.machines?.length or 0


  onHeaderTitleClick: ({ template, stack }) ->

    { router } = kd.singletons

    route = if stack?.isManaged()
    then '/Home/stacks/virtual-machines#connected-machines'
    else "/Stack-Editor/#{template.getId()}"

    router.handleRoute route


  onHeaderMenuItemClick: (resource, item) ->

    MENU.destroy()

    { appManager, router, linkController, computeController } = kd.singletons

    { stack, template } = resource
    { title } = item.getData()

    switch title

      when 'Edit', 'View Stack'
        router.handleRoute "/Stack-Editor/#{template.getId()}"

      when 'Initialize'
        template.generateStack { verify: yes }, (err, stack) =>
          return @onMenuItemClickError 'initializing', template.getId()  if err
          router.handleRoute "/Stack-Editor/#{template.getId()}"
          appManager.tell 'Stackeditor', 'reloadEditor', template.getId()
          if machine = stack.results?.machines?[0]?.obj
            computeController.reloadIDE machine

      when 'Reinitialize', 'Update'
        computeController.reinitStack stack, (err) =>
          return @onMenuItemClickError 'reinitializing', template.getId()  if err
          appManager.tell 'Stackeditor', 'reloadEditor', template.getId()

      when 'Clone'
        computeController.fetchStackTemplate template.getId(), (err, template) =>
          return @onMenuItemClickError 'cloning'  if err
          template.clone (err, template) =>
            return @onMenuItemClickError 'cloning'  if err
            router.handleRoute "/Stack-Editor/#{template.getId()}"

      when 'Destroy VMs'
        computeController.ui.askFor 'deleteStack', {}, (status) =>
          return  unless status.confirmed
          computeController.destroyStack stack, (err) =>
            return @onMenuItemClickError 'destroying'  if err
          , followEvents = no

      when 'Delete'
        computeController.deleteStackTemplate template

      when 'VMs'
        firstMachineId = stack.machines.first.getId()
        router.handleRoute "/Home/stacks/virtual-machines/#{firstMachineId}"

      when 'Open on GitLab'
        { originalUrl } = stack.config.remoteDetails
        linkController.openOrFocus originalUrl

      when 'Make Team Default'
        computeController.fetchStackTemplate template.getId(), (err, template) =>
          return @onMenuItemClickError 'making team default'  if err
          if template
            computeController.makeTeamDefault template

      when 'Share With Team'
        computeController.fetchStackTemplate template.getId(), (err, template) =>
          return @onMenuItemClickError 'sharing'  if err
          if template
            computeController.setStackTemplateAccessLevel template, 'group'

      when 'Make Private'
        computeController.fetchStackTemplate template.getId(), (err, template) =>
          return @onMenuItemClickError 'cloning'  if err
          if template
            computeController.setStackTemplateAccessLevel template, 'private'


  onHeaderMenuClick: (sectionIndex, resource) ->

    return  if MENU

    if resource.stack
    then @onStackMenuIconClick sectionIndex, resource
    else @onDraftMenuIconClick sectionIndex, resource


  onStackMenuIconClick: (sectionIndex, resource) ->

    callback = @lazyBound 'onHeaderMenuItemClick', resource
    menuItems = {}
    { stack, template } = resource


    if !!resource.unreadCount
      menuItems['Update'] = { callback }

    if stack.config?.remoteDetails?.originalUrl?
      menuItems['Open on GitLab'] = { callback }

    if stack.isManaged()
      menuItems['VMs'] = { callback }

    else if stack.disabled
      # because of disabled stack's baseTemplate came undefined
      # no need to show Edit, Clone, Reinitialize options
      ['VMs', 'Destroy VMs'].forEach (name) -> menuItems[name] = { callback }

    else

      isMyTemplate = template?.originId is whoami()._id

      debug 'accessLevel', template.accessLevel

      if isAdmin() or isMyTemplate
        menuItems['Edit'] = { callback }

        if canCreateStacks()
          menuItems['Clone'] = { callback }

      else
        menuItems['View Stack'] = { callback }

      ['Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }

      if isAdmin() and not isDefaultTeamStack stack.baseStackId
        menuItems['Make Team Default'] = { callback }

      if isMyTemplate and not isDefaultTeamStack stack.baseStackId

        if template.accessLevel is 'private'
          menuItems['Share With Team'] = { callback }

        if template.accessLevel is 'group'
          menuItems['Make Private'] = { callback }


    { top } = findDOMNode(@headers[sectionIndex]).getBoundingClientRect()

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: top + 31 }
    MENU = new kd.ContextMenu menuOptions, menuItems
    MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> MENU = null


  onDraftMenuIconClick: (sectionIndex, resource) ->

    callback = @lazyBound 'onHeaderMenuItemClick', resource
    menuItems = {}
    { template } = resource

    if template.config?.remoteDetails?.originalUrl
      menuItems['Open on GitLab'] = { callback }

    if template.isMine()
    then menuItems['Edit'] = { callback }
    else menuItems['View Stack'] = { callback }

    if canCreateStacks() or isAdmin()
      menuItems['Clone'] = { callback }


    if template.machines.length
      if isAdmin()
        menuItems['Make Team Default'] = { callback }

      if template.isMine()
        if template.accessLevel is 'private'
        then menuItems['Share With Team'] = { callback }
        else menuItems['Make Private'] = { callback }

    menuItems['Initialize'] = { callback }
    menuItems['Delete'] = { callback }

    { top } = findDOMNode(@headers[sectionIndex]).getBoundingClientRect()

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: top + 31 }
    MENU = new kd.ContextMenu menuOptions, menuItems
    MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> MENU = null


  renderSectionHeaderAtIndex: (sectionIndex) ->

    resource = @props.resources[sectionIndex]

    { template, stack, unreadCount } = resource

    <OwnedResourceHeader
      ref={(header) => @headers[sectionIndex] = header}
      title={template?.title or stack?.title}
      onTitleClick={@lazyBound 'onHeaderTitleClick', resource}
      onMenuIconClick={@lazyBound 'onHeaderMenuClick', sectionIndex, resource}
      unreadCount={unreadCount} />


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    debug 'render row at index', { sectionIndex, rowIndex }

    unless stack = @props.resources[sectionIndex].stack
      return null

    machine = stack.machines[rowIndex]

    <SidebarMachineItem
      machineId={machine.getId()}
      stackId={stack.getId()} />


  renderEmpty: ->

    debug 'render empty section'

    <SidebarNoStacks
      hasTemplate={@props.hasTemplate}
      hasPermission={canCreateStacks()} />


  render: ->

    <div className='SidebarTeamSection'>
      <SectionHeader />
      <List
        sectionClassName='SidebarSection SidebarStackSection'
        rowClassName='SidebarSection-body'
        numberOfSections={@bound 'getSectionCount'}
        renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
        renderEmpty={@bound 'renderEmpty'}
        numberOfRowsInSection={@bound 'getRowCount'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
      />
    </div>


SectionHeader = ({ children }) ->

  <Link className='SidebarSection-headerTitle' href='/Home/stacks'>
    STACKS
  </Link>
