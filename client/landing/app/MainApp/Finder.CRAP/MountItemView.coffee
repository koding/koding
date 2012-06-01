class MountItemView extends FolderItemView

  classContextMenuItems: ->
    divider = { type : 'divider', id : null, parentId : null }
    items = [
        { title : "Expand",         id : 0,   parentId : null, action : "expandFolder" }
        divider
        { title : "New file",       id : 13,  parentId : null, action : "createFile" }
        { title : "New folder",     id : 14,  parentId : null, action : "createFolder" }
        { title : 'Upload File...', id : 15,  parentId : null, action : 'upload',      disabledForBeta : yes }
        divider
        { title : 'Refresh',        id : 102, parentId : null, action : 'refresh'}
      ]
    uberItems = FinderItemView::classContextMenuItems.call @
    items.concat uberItems
