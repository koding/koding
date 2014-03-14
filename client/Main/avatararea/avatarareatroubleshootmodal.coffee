class TroubleshootModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->
    troubleshoot = KD.singleton("troubleshoot")

    options =
        title                 : "Check Koding Status"
        overlay               : yes
        tabs                  :
          forms               :
            Troubleshoot      :
              callback        : =>
                {feedback} = @modalTabs.forms.Troubleshoot.customData
                KD.logToExternal "troubleshoot feedback", {failure:troubleshoot.getFailureFeedback(), feedback}
                @destroy()
              buttons         :
                sendFeedback    :
                  title       : "Send Feedback"
                  style       : "modal-clean-gray"
                  type        : "submit"
                  loader      :
                    color     : "#444444"
                    diameter  : 12
                  callback    : -> @hideLoader()
                close         :
                  title       : "Close"
                  style       : "modal-cancel"
                  callback    : => @destroy()
              fields          :
                check         :
                  label       : "System Status"
                  itemClass   : TroubleshootStatusView
                feedback      :
                  label       : "Feedback"
                  itemClass   : KDInputView
                  name        : "feedback"
                  placeholder : "Define the situation"

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

