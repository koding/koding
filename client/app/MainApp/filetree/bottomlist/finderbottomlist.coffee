class FinderBottomControls extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName   : "ul"
      itemClass : FinderBottomControlsListItem
    ,options
    super options,data

