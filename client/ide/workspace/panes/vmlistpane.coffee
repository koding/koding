class IDE.VMListPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'vm-list-pane', options.cssClass

    super options, data

    @fetchMachines()

  fetchMachines: ->
    KD.getSingleton('computeController').fetchMachines (err, machines) =>
      if err
        ErrorLog.create "IDE: Couldn't fetch machines", reason: err
        return new KDNotificationView
          title : "Couldn't fetch your machines"
          type  : 'mini'

      for machine in machines when machine.status.state is Machine.State.Running
        @addSubView new IDE.VMPaneListItem {}, machine

      @addBuyVMButton()

  addBuyVMButton: ->
    buyVMButton  = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'buy-vm-button'
      partial    : '<span class="icon"></span>Buy another VM'
      attributes :
        href     : '/Pricing'

    @addSubView buyVMButton


class IDE.VMPaneListItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'vm-item', options.cssClass

    super options, data

    @unsetClass 'kdview'

    @createElements()

  createElements: ->
    appManager     = KD.getSingleton 'appManager'
    data           = @getData()

    @domainName    = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'domain-name'
      partial      : data.getName()
      click        : @bound 'openVMDomain'

    @actionsButton = new KDButtonView
      title        : ''
      iconClass    : 'icon'
      cssClass     : 'actions-menu'
      callback     : @bound 'createContextMenu'

  openVMDomain: ->
    KD.getSingleton('appManager').tell 'IDE', 'openMachineWebPage', @getData()

  createContextMenu: (event) ->
    button         = @actionsButton
    @contextMenu   = new KDContextMenu
      cssClass     : 'environments'
      event        : event
      delegate     : this
      x            : button.getX() - 146
      y            : button.getY() + 20
      arrow        :
        placement  : 'top'
        margin     : 150
    , @getMenuItems()

    @contextMenu.on 'ContextMenuItemReceivedClick', => @contextMenu.destroy()

  getMenuItems: ->
    data        = @getData()
    appManager  = KD.getSingleton 'appManager'
    menuItems   =
      'Mount to filetree': callback: -> appManager.tell 'IDE', 'mountMachine', data
      'Open VM terminal' : callback: -> appManager.tell 'IDE', 'openMachineTerminal', data
      'Open VM domain'   : callback: @bound 'openVMDomain'

    # FIXME: Find a better way to remove this drill down
    ideAppController   = appManager.getFrontApp()
    {finderController} = ideAppController.workspace.panel.getPaneByName('filesPane').finderPane
    isVMAlreadyMounted = finderController.getMachineNode data.uid

    if isVMAlreadyMounted
      delete menuItems['Mount to filetree']
      menuItems['Unmount from filetree'] =
        callback : =>
          appManager.tell 'IDE', 'unmountMachine', data

    return menuItems

  pistachio: ->
    """
      {{> @domainName}}
      {{> @actionsButton}}
    """
