class TroubleshootStatusView extends KDCustomHTMLView

  constructor: (options, data) ->
    {items: data} = KD.singleton("troubleshoot")
    options.cssClass = "troubleshoot-status"

    super options, data

    items = @getStatus()

    for own name, title of items
      @createItem name, title

  getStatus: ->
    premium = if KD.config.usePremiumBroker then "Premium " else ""

    connection  : "Internet Connection"
    bongo       : "Social Server"
    liveUpdate  : "Live Updates"
    broker      : "#{premium} Messaging Server"
    brokerKite  : "#{premium} Kite Messaging Server"
    osKite      : "VM Server"
    vm          : "Your VMs"
    webServer   : "Webserver"
    version     : "Latest version"

  createItem: (name, title) ->
    if @getData()[name]
      item = new TroubleshootItemView
        title : title
      , @getData()[name]

      @addSubView item
