class IDE.VMListPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'vm-list-pane', options.cssClass

    super options, data

    @fetchVMs()

  fetchVMs: ->
    {vmController, kontrol} = KD.singletons
    vmController.fetchVMs (err, vms) =>
      if err
        ErrorLog.create "terminal: Couldn't fetch vms", reason: err
        return new KDNotificationView
          title : "Couldn't fetch your VMs"
          type  : 'mini'

      vms.sort (first, second) ->
        return first.hostnameAlias > second.hostnameAlias

      for vm in vms
        @addSubView new IDE.VMPaneListItem {}, vm

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
      partial      : data.hostnameAlias.replace 'koding.kd.io', 'kd.io'
      click        : @bound 'openVMDomain'

    @actionsButton = new KDButtonView
      title        : ''
      iconClass    : 'icon'
      cssClass     : 'actions-menu'
      callback     : @bound 'createContextMenu'

  openVMDomain: ->
    KD.getSingleton('appManager').tell 'IDE', 'openVMWebPage', @getData()

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
      'Mount to filetree': callback: -> appManager.tell 'IDE', 'mountVM', data
      'Open VM terminal' : callback: -> appManager.tell 'IDE', 'openVMTerminal', data
      'Open VM domain'   : callback: @bound 'openVMDomain'

    # FIXME: Find a better way to remove this drill down
    ideAppController   = appManager.getFrontApp()
    {finderController} = ideAppController.workspace.panel.getPaneByName('filesPane').finderPane
    isVMAlreadyMounted = finderController.getVmNode data.hostnameAlias

    if isVMAlreadyMounted
      delete menuItems['Mount to filetree']
      menuItems['Unmount from filetree'] =
        callback : =>
          appManager.tell 'IDE', 'unmountVM', data

    return menuItems

  pistachio: ->
    """
      {{> @domainName}}
      {{> @actionsButton}}
    """
