class FinderContextMenu extends KDContextMenu
  hide: ->
    (@getSingleton "windowController").setKeyView @getDelegate()
    @destroy()