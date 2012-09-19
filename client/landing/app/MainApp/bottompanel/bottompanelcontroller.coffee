class BottomPanelController extends KDViewController

  loadView:(bottomPanel)->

    @isVisible   = no
    @bottomPanel = bottomPanel
    @wc          = @getSingleton("windowController")

    bottomPanel.on "ToggleBottomPanel", => @toggle()
    bottomPanel.on "ReceivedClickElsewhere", (event)=> @hide event

    bottomPanel.addSubView split = new SlidingSplit
      cssClass        : "chat-split"
      sizes           : [null]

  toggle:-> if @isVisible then @hide() else @show()

  show:->

    return unless location.hostname is "localhost"
    @isVisible = yes
    @bottomPanel.setClass 'in'
    @wc.addLayer @bottomPanel

  hide:(event)->

    @isVisible = no
    @bottomPanel.unsetClass 'in'
