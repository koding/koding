class TroubleshootModal extends KDModalView

  constructor: (options = {}, data) ->
    super options, data

    KD.troubleshoot()

    @init()
class TroubleshootStatus extends KDCustomHTMLView

  constructor: (options, data) ->
    data = KD.singleton("troubleshoot").getItems()
    super options, data

    @bongo = new TroubleshootItemView
      title: "Bongo"
    , @getData()["bongo"]

    @broker = new TroubleshootItemView
      title : "Broker"
    , @getData()["broker"]

    @kiteBroker = new TroubleshootItemView
      title : "Kite-Broker"
    , @getData()["kiteBroker"]

    @osKite = new TroubleshootItemView
      title : "OS-Kite"
    , @getData()["osKite"]

    @webServer = new TroubleshootItemView
      title : "Webserver"
    , @getData()["webServer"]

    @connection = new TroubleshootItemView
      title : "Internet Connection"
    , @getData()["connection"]

    @version = new KDCustomHTMLView
      title : "Build Version: #{KD.config.version}"

    @addSubView @bongo
    @addSubView @broker
    @addSubView @kiteBroker
    @addSubView @osKite
    @addSubView @webServer
    @addSubView @connection
    @addSubView @version


class TroubleshootItemView extends KDCustomHTMLView

  constructor: (options, data) ->

    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes

    @getData().on "healthCheckCompleted", =>
      @loader.hide()
      @render()


  viewAppended: ->
    JView::viewAppended.call this


  getResponseTime: ->
    responseTime = @getData().getResponseTime()
    return "#{responseTime} ms" unless responseTime is ""

    responseTime


  pistachio:->
    {title} = @getOptions()
    """
      {{> @loader}}  #{title} : {{ #(status) }} {{@getResponseTime #(dummy) }}
    """

