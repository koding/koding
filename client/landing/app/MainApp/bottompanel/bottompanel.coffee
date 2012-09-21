class BottomPanel extends KDScrollView

  constructor:->

    super

    @listenWindowResize()

  _windowDidResize:->

    @utils.wait 300, =>
      @setWidth @getSingleton('contentPanel').getWidth()