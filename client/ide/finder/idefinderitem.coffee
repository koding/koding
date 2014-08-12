class IDE.FinderItem extends NFinderItem

  getChildConstructor: (type) ->
    switch type
      when 'machine'    then IDE.MachineItemView
      when 'folder'     then NFolderItemView
      when 'section'    then NSectionItemView
      when 'mount'      then NMountItemView
      when 'brokenLink' then NBrokenLinkItemView
      else NFileItemView
