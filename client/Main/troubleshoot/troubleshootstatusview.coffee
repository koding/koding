class TroubleshootStatusView extends KDCustomHTMLView

  constructor: (options, data) ->
    {items: data} = KD.singleton("troubleshoot")
    options.cssClass = "troubleshoot-status"
    super options, data

    premium = if KD.config.usePremiumBroker then "VIP " else ""
    @createItem "connection", "Internet Connection"
    @createItem "bongo", "Social Server"
    @createItem "liveUpdate", "Live Updates"
    @createItem "broker", "#{premium} Messaging Server"
    @createItem "brokerKite", "#{premium} Kite Messaging Server"
    @createItem "osKite", "VM Server"
    @createItem "vm", "VMs"
    @createItem "webServer", "Webserver"
    @createItem "version", "Latest version"

  createItem: (name, title) ->
    if @getData()[name]
      item = new TroubleshootItemView
        title : title
      , @getData()[name]

      @addSubView item
