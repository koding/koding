class TroubleshootErrorView extends KDCustomHTMLView

  errorMessages =
    bongo      :
      slow     : "You will experience slowness with posting status updates and \
                 receiving feeds. Generally interacting with social"
      down     : "You will be having problems with posting status updates and \
                 receiving feeds. Generally interacting with social"
    broker:
      slow     : "You will experience slowness with live updates"
      down     : "You will not receive live updates, and you wont be able to \
                 connect to your vms"
    brokerKite :
      slow     : "You will experience slowness with terminal connection"
      down     : "You will not connect to your terminal"
    osKite     :
      slow     : "You will experience slowness with terminal connection"
      down     : "You will not connect to your terminal"
    webServer  :
      slow     : "Page load time is probably slow"
      down     : "Webserver is not responding now. Please do not refresh your page"
    connection :
      slow     : "Your internet connection is very slow. Your experience with \
                 Koding will not be the best one"
      down     : "You do not have internet at the moment. The parts of Koding that \
                 supports offline working will continue to work, but you cannot \
                 send/receive updates, reach your VMs nor interact with terminal."
    liveUpdate :
      slow     : "You will not receive live updates, and you wont be able to \
                  connect to your vms"
      fail     : "You will experience slowness with live updates"


  constructor: (options, data) ->
    options.cssClass = "troubleshoot-errors"
    super options, data
    @hide()
    @initStatusListener()
    # @addSubView new KDCustomHTMLView
    #   partial: "<strong>#{errorMessages['bongo']['down']}</strong>"
    #   cssClass: "status-message"
    # @addSubView new KDCustomHTMLView
    #   partial: errorMessages["broker"]["down"]
    # @addSubView new KDCustomHTMLView
    #   partial: errorMessages["brokerKite"]["down"]


  initStatusListener: ->
    items = KD.singleton("troubleshoot").getItems()
    for own name, item of items
      do (name, item) =>
        item.once "healthCheckCompleted", =>
          if item.status is "down"
            @show()
            @addSubView new KDCustomHTMLView
              tagName: "strong"
              cssClass: "status-message"
              partial: errorMessages[name]["down"]
