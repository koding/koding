class BottomPanelController extends KDController

  constructor:->

    super

    @panels = {}
    @createPanel name : "terminal"
    @createPanel name : "chat", panelClass : BottomChatPanel

    @on "TogglePanel", @togglePanel.bind @

  createPanel:(options = {})->

    return unless options.name
    {panelClass} = options
    delete options.panelClass if options.panelClass
    @getSingleton('mainView').addSubView panel = new (panelClass or BottomPanel) options
    @panels[options.name] = panel
    return panel

  togglePanel:(name)->

    return unless panel = @panels[name]

    if panel.isVisible then panel.hide() else panel.show()

  destroyPanel:(name)->

    return unless panel = @panels[name]

    delete @panels[name]
    panel.hide ->
      panel.destroy()

    return

  showPanel:(name)->

    return unless panel = @panels[name]
    panel.show()
    return panel

  hidePanel:(name)->

    return unless panel = @panels[name]
    panel.hide()
    return panel