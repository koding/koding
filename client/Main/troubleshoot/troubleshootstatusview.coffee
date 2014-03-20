class TroubleshootStatusView extends KDCustomHTMLView

  constructor: (options, data) ->
    data = KD.singleton("troubleshoot").getItems()
    options.cssClass = "troubleshoot-status"
    super options, data

    premium = if KD.config.usePremiumBroker then "Premium " else ""
    @createItem "connection", "Internet Connection"
    @createItem "bongo", "Bongo"
    @createItem "liveUpdate", "Live Update"
    @createItem "broker", "#{premium} Broker"
    @createItem "brokerKite", "#{premium} Broker Kite"
    @createItem "osKite", "OS-Kite"
    @createItem "vm", "VMs"
    @createItem "webServer", "Webserver"
    @createItem "version", "Latest version"

  createItem: (name, title) ->
    if @getData()[name]
      item = new TroubleshootItemView
        title : title
      , @getData()[name]

      @addSubView item
