class FinderBottomControls extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      subItemClass : FinderBottomControlsListItem
    ,options
    super options,data

