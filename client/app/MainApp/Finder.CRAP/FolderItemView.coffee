class FolderItemView extends FinderItemView
  constructor:(options,data)->
    super options,data
    @needsSubItemsRefresh = yes
  
  subfilesRefreshed:()->
    @needsSubItemsRefresh = no
    @expandIfNecessary()
  
  expandIfNecessary:()->
    if !!@waitingToExpand or @expanded
      @getDelegate().expandItem @
      @waitingToExpand = no

  removeSubfiles:(data, controller)=>
    item = (controller.itemForData data) or controller.archivedItems[data.path] #FIXME: necessary?
    # controller.removeTreeItem item
    if item
      controller.removeItem item
    else
      log 'item isnt found, nothing to cleanup'

  classContextMenuItems: ->
    divider = { type : 'divider', id : null, parentId : null }
    items = [
        { title : "Expand",              id : 300,   parentId : null, action : "expandFolder" }
        { title : 'Download',            id : 310,   parentId : null, action : 'download' }
        { title : "Compress",            id : 320,   parentId : null, action : "compress" }
        { title : 'Set Permissions...',  id : 330,   parentId : null, action : '' }
          { title : 'Sinan fixed!',      id : 340,   parentId : 330,   type : 'permissionsSetter'}
        divider
        { title : 'Delete',              id : 350,   parentId : null, action : 'remove', callback : @performRemove }
        divider
        { title : "Rename...",           id : 360,   parentId : null, action : "rename", callback : @performRename }
        { title : "Duplicate",           id : 370,   parentId : null, action : "duplicateFile" }
        { title : "New file",            id : 380,   parentId : null, action : "createFile" }
        { title : "New folder",          id : 390,   parentId : null, action : "createFolder" }
        { title : 'Upload File...',      id : 400,   parentId : null, action : 'upload' , disabledForBeta : yes}
        { title : 'Clone GitHub...',     id : 410,   parentId : null, action : 'gitHubClone' , disabledForBeta : yes}
        divider
        { title : 'Refresh',             id : 420,   parentId : null, action : 'refresh'}
      ]
    items.concat super
