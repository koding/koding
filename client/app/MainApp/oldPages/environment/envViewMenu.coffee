class EnvironmentViewMenu extends KDListView
  # LIST ITEM CLASS

  listItemClass = class EnvironmentViewMenuListItem extends KDListItemView
    partial:(data)->
      """
        #{data.title}
      """

    setDomElement:(cssClass)->
      @domElement = $ "<li class='kdview #{cssClass} #{@getData().id}'></li>"
  # /LIST ITEM CLASS ENDS

  constructor:(options,data)->
    options = $.extend
      itemClass : listItemClass
    ,options
    super options,data

  viewAppended:->
    @setPartial "<li class='header'>VIEW</li>"
    @setClass "common-inner-nav"
    super

  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"
