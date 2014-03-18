class TroubleshootErrorView extends KDCustomHTMLView

  errorMessages =
    bongo      :
      slow     : "You will experience slowness with posting status updates and \
                 receiving feeds. Generally interacting with social"
      fail     : "You will be having problems with posting status updates and \
                 receiving feeds. Generally interacting with social"
    broker:
      slow     : "You will experience slowness with live updates"
      fail     : "You will not receive live updates, and you wont be able to \
                 connect to your vms"
    brokerKite :
      slow     : "You will experience slowness with terminal connection"
      fail     : "You will not connect to your terminal"
    osKite     :
      slow     : "You will experience slowness with terminal connection"
      fail     : "You will not connect to your terminal"
    webServer  :
      slow     : "Page load time is probably slow"
      fail     : "Webserver is not responding now. Please do not refresh your page"
    connection :
      slow     : "Your internet connection is very slow. Your experience with \
                 Koding will not be the best one"
      fail     : "You do not have internet at the moment. The parts of Koding that \
                 supports offline working will continue to work, but you cannot \
                 send/receive updates, reach your VMs nor interact with terminal."
    liveUpdate :
      slow     : "You will not receive live updates, and you wont be able to \
                  connect to your vms"
      fail     : "You will experience slowness with live updates"
    version    :
      fail     : "You are currently running an old version of Koding. Please refresh \
                  your page."
    vm         :
      fail     : "Your VMs are not accessible"


  constructor: (options, data) ->
    options.cssClass = "troubleshoot-errors"
    super options, data
    @hide()
    @initStatusListener()


  initStatusListener: ->
    items = KD.singleton("troubleshoot").getItems()
    for own name, item of items
      do (name, item) =>
        item.once "healthCheckCompleted", =>
          {status} = item
          if status in ["fail", "slow"] and errorMessages[name]?[status]
            @show()
            @addSubView new KDCustomHTMLView
              tagName: "div"
              cssClass: "status-message #{status}"
              partial: "* #{errorMessages[name][status]}"

