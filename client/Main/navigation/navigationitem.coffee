class NavigationItem extends JTreeItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.type or= 'main-nav'

    super options, data

    data  = @getData()
    @type = data.type

    if      data.jMachine                then @createMachineItem      data
    else if data.type is 'title'         then @createTitleView        data
    else if data.type is 'new-workspace' then @createNewWorkspaceView data
    else if data.type is 'workspace'     then @createWorkspaceItem    data
    else if data.type is 'app'           then @createAppItem          data


  createMachineItem: (data) ->
    @type  = 'machine'
    @setClass 'machine'
    @child = new NavigationMachineItem {}, data


  createTitleView: (data) ->
    @setClass 'sub-title'
    @child = new KDCustomHTMLView
      tagName : 'h3'
      partial : data.title
      click   : (event) =>
        KD.utils.stopDOMEvent event
        if event.target.classList.contains 'ws-add-icon'
          KD.singletons.mainView.activitySidebar.addNewWorkspace this


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

          new WorkspaceSettingsPopup {position}, @getData()


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
