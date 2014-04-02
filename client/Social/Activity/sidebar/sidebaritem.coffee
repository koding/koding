class SidebarItem extends KDListItemView

  constructor: ->

    super

    {activityController} = KD.singletons
    activityController.on 'SidebarItemClicked', @bound 'selectItem'


  selectItem: (item)->

    if item.getId() is @getId()
      @setClass 'selected'
    else
      @unsetClass 'selected'


  click: ->

    {activityController} = KD.singletons
    activityController.emit 'SidebarItemClicked', this
