class NavigationItem extends JTreeItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.type or= 'main-nav'

    super options, data

    data  = @getData()
    @type = data.type

    if      data.jMachine                then @createMachineItem      data
    else if data.type is 'title'         then @createMoreLink         data
    else if data.type is 'new-workspace' then @createNewWorkspaceView data
    else if data.type is 'workspace'     then @createWorkspaceItem    data
    else if data.type is 'app'           then @createAppItem          data


  createMachineItem: (data) ->
    @type  = 'machine'
    @setClass 'machine'
    @child = new NavigationMachineItem {}, data


  createMoreLink: (data) ->

    @setClass 'sub-title'
    { activitySidebar } = KD.singletons.mainView
    { title } = @getData()
    data.delegate = @getDelegate()

    @child = new SidebarMoreLink
      title   : title
      tagName : 'a'
      click   : (event) ->
        KD.utils.stopDOMEvent event
        activitySidebar.emit 'MoreWorkspaceModalRequested', data

  createWorkspaceItem: (data) ->
    @setClass 'workspace'
    @child    = new KDCustomHTMLView
      partial : """
        <figure></figure>
        <a href='#{KD.utils.groupifyLink data.href}'>#{data.title}</a>
      """
      click   : (event) =>
        if event.target.classList.contains 'ws-settings-icon'
          KD.utils.stopDOMEvent event

          bounds   = this.getBounds()
          position =
            top    : Math.max bounds.y - 38, 0
            left   : bounds.x + bounds.w + 16

          new WorkspaceSettingsPopup {position}, this


  createNewWorkspaceView: ->
    @setClass 'workspace'
    { machineUId, machineLabel } = @getData()

    @child = new AddWorkspaceView {}, { machineUId, machineLabel }


  createAppItem: ->
    @setClass 'app'
    @child    = new KDCustomHTMLView
      partial : """
        <figure></figure>
        <a href='#{KD.utils.groupifyLink data.href}'>#{data.title}</a>
      """


  pistachio: ->
    """
      {{> @child}}
    """
