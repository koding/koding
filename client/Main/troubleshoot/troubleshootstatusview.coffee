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

    connection  : "Internet connection"
    bongo       : "Social server"
    liveUpdate  : "Live updates"
    broker      : "#{premium}Messaging server"
    brokerKite  : "#{premium}Kite messaging server"
    newKite     : "New Kites"
    osKite      : "VM server"
    vm          : "Your VMs"
    terminal    : "Terminals"
    webServer   : "Webserver"
    version     : "Latest version"

  createItem: (name, title) ->
    if @getData()[name]
      item = new TroubleshootItemView
        title : title
      , @getData()[name]

      @addSubView item
