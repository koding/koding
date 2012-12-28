class SidebarResizeHandle extends KDView

  constructor:(options, data)->

    options.bind    = "mousemove"
    options.partial = "<span></span>"
    super options, data

    @setDraggable axis : "x"
