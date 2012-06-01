class FileItemView extends FinderItemView
  constructor: ->
    super

    fileData = @getData()
    
    fileData.on 'change', ({modified}) => @changed modified
    fileData.on 'save.start', =>  @showLoader()
    fileData.on 'save.finish', => @hideLoader()
    
  changed: (changed) ->
    if changed then @setClass "unsaved" else @unsetClass "unsaved"
    
  render:->
    super
    @decorateItem()

  performOpenWithFile: (a, b, c) =>
    log a, b, c, @, '<>'

  classContextMenuItems:->

    divider = (parent)-> { type : 'divider', id : null, parentId : parent or null }

    archiveOption = if 'archive' is __utils.getFileType __utils.getFileExtension @getData().name
      { title : "Extract",  id : 10, parentId : null, action : "extract" }
    else
      { title : "Compress", id : 10, parentId : null, action : "compress" }

    items = [
        { title : 'Open File',              id : 10,    parentId : null,  action : 'openFile' }
        { title : 'Open With...',           id : 20,    parentId : null }
          { title : 'Ace Editor',           id : 210,   parentId : 20,    action : 'openFile' }
          { title : 'CodeMirror',           id : 220,   parentId : 20,    action : 'openFileWithCodeMirror' }
          { title : 'Viewer',               id : 230,   parentId : 20,    action : 'previewFile' }
          { title : 'Search the App Store', id : 240,   parentId : 20,    disabledForBeta : yes}
          { title : 'Contribute an Editor', id : 250,   parentId : 20,    disabledForBeta : yes}
        divider()
        { title : 'Delete',                 id : 40,    parentId : null,  action : 'removeSelectedFiles' }
        divider()                             
        { title : "Rename...",              id : 50,    parentId : null,  action : "rename", callback : @performRename }
        { title : "Duplicate",              id : 60,    parentId : null,  action : "duplicateFile" }
        { title : 'Set Permissions...',     id : 70,    parentId : null,  action : '' }
          { title : 'Sinan fixed',          id : 80,    parentId : 70,    type : 'permissionsSetter' }
        # archiveOption
        { title : 'Download',               id : 90,    parentId : null,  action : 'download' }
        divider()                             
        { title : "New file",               id : 100,   parentId : null,  action : "createFile" }
        { title : "New folder",             id : 110,   parentId : null,  action : "createFolder" }
        { title : 'Upload File...',         id : 120,   parentId : null,  action : 'upload' ,       disabledForBeta : yes }
        { title : 'Clone GitHub...',        id : 130,   parentId : null,  action : 'gitHubClone' ,  disabledForBeta : yes }
      ]

    items.concat super
