class EditorHeaderButtons_ContextMenu extends KDContextMenuTreeViewController
  itemClass: (options, data) ->
    switch data.type
      when 'autosave'
        item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
        item.addSubView new KDRySwitch
          type: 'checkbox'
          defaultValue: data.default()
          callback: (state)->
            data.callback state
        item
      else
        super
