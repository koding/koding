class Editor_ContextMenuTreeViewController extends KDContextMenuTreeViewController
  itemClass: (options, data)->
    switch data.type
      when 'divider'
        item = new KDContextMenuListItemSeparator options, data
      else
        unless data.disabledForBeta
          item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
          item.registerListener KDEventTypes : ['click'], callback : @clickOnMenuItem, listener : @
        else
          $.extend options, cssClass:'disabledForBeta'
          item = new DisabledFinderContextMenuItemView options, data
    item