class TroubleshootStatusView extends KDCustomHTMLView

  constructor: (options, data) ->
    data = KD.singleton("troubleshoot").getItems()
    options.cssClass = "troubleshoot-status"
    super options, data

    premium = if KD.config.usePremiumBroker then "Premium " else ""

    @bongo = new TroubleshootItemView
      title       : "Bongo"
    , @getData()["bongo"]

    @liveUpdate = new TroubleshootItemView
      title       : "Live Update"
    , @getData()["liveUpdate"]

    @broker = new TroubleshootItemView
      title : "#{premium} Broker"
    , @getData()["broker"]

    @brokerKite = new TroubleshootItemView
      title : "#{premium} Broker Kite"
    , @getData()["brokerKite"]

    @osKite = new TroubleshootItemView
      title : "OS-Kite"
    , @getData()["osKite"]

    @vm = new TroubleshootItemView
      title : "VMs"
    , @getData()["vm"]

    @webServer = new TroubleshootItemView
      title : "Webserver"
    , @getData()["webServer"]

    @connection = new TroubleshootItemView
      title : "Internet Connection"
    , @getData()["connection"]

    @version = new TroubleshootItemView
      title : "Latest version"
    , @getData()["version"]

    @addSubView @connection
    @addSubView @bongo
    @addSubView @liveUpdate
    @addSubView @broker
    @addSubView @brokerKite
    @addSubView @osKite
    @addSubView @vm
    @addSubView @webServer
    @addSubView @version
