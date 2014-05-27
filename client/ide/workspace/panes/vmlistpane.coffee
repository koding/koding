class VMListPane extends Pane

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

      vms.sort (a,b) ->
        return a.hostnameAlias > b.hostnameAlias

      for vm in vms
        @addSubView new VMPaneListItem {}, vm

      @addBuyVMButton()

  addBuyVMButton: ->
    buyVMButton  = new KDButtonView
      title      : 'Buy another VM'
      cssClass   : 'solid green medium'
      callback   : -> KD.getSingleton('router').handleRoute '/Pricing'

    @addSubView buyVMButton


class VMPaneListItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'vm-item', options.cssClass

    super options, data

    @unsetClass 'kdview'

    @createElements()

  createElements: ->
    appManager = KD.getSingleton 'appManager'
    data       = @getData()

    @label     = new KDCustomHTMLView
      tagName  : "span"
      partial  : data.hostnameAlias.replace 'koding.kd.io', 'kd.io'

    @openTerminalButton = new KDButtonView
      title    : "T"
      cssClass : "mini solid green"
      callback : -> appManager.tell 'IDE', 'openVMTerminal', data

    @openWebPageButton = new KDButtonView
      title    : "W"
      cssClass : "mini solid gray"
      callback : -> appManager.tell 'IDE', 'openVMWebPage', data

  pistachio: ->
    """
      {{> @label}}
      {{> @openTerminalButton}}
      {{> @openWebPageButton}}
    """