class BottomPanel extends KDScrollView

  constructor:(options, data)->

    options.name     or= "panel#{Date.now()}"
    options.cssClass or= "bottom-panel #{@utils.slugify options.name}"

    super options, data

    @wc = @getSingleton("windowController")
    @listenWindowResize()
    @isVisible = no
    @on "ReceivedClickElsewhere", => @hide()

  _windowDidResize:->

    @utils.wait 300, =>
      @setWidth @getSingleton('contentPanel').getWidth() + 10

  show:(cb = noop)->

    return unless location.hostname is "localhost"
    @isVisible = yes
    @setClass 'in'
    @wc.addLayer @
    @utils.wait 300, cb.bind @
    return @

  hide:(cb = noop)->

    @isVisible = no
    @unsetClass 'in'
    @wc.removeLayer @
    @utils.wait 300, cb.bind @
    return @



    # bottomPanel.on "ToggleBottomPanel", => @toggle()
    # bottomPanel.on "ReceivedClickElsewhere", (event)=> @hide event

    # bottomPanel.addSubView @chatSidebar = new BottomChatSideBar
    #   cssClass : "chat-sidebar"

    # bottomPanel.addSubView splitWrapper = new KDScrollView
    #   cssClass : "split-wrapper"


    # splitWrapper.addSubView @split = new SlidingSplit
    #   cssClass : "chat-split"
    #   sizes    : [null]
    #   views    : [new KDView]

    # @split.on "panelSplitted", (panel)->
    #   panel.addSubView new KDView
