class BottomPanel extends KDScrollView

  constructor:->

    super

    @listenWindowResize()
    @isVisible = no

  _windowDidResize:->

    @utils.wait 300, =>
      @setWidth @getSingleton('contentPanel').getWidth() + 10

  show:->

    return unless location.hostname is "localhost"
    @isVisible = yes
    @setClass 'in'
    @wc.addLayer @
    @split.setFocusedPanel @split.panels[0]

  hide:(event)->

    @isVisible = no
    @unsetClass 'in'
