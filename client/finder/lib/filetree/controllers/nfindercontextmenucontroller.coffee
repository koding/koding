_ = require 'lodash'
kd = require 'kd'
KDContextMenu = kd.ContextMenu
KDController = kd.Controller
nick = require 'app/util/nick'
FSHelper = require 'app/util/fs/fshelper'
NSetPermissionsView = require '../itemsubviews/nsetpermissionsview'


module.exports = class NFinderContextMenuController extends KDController

  ###
  CONTEXT MENU CREATION
  ###

  getMenuItems: (fileViews) ->

    if fileViews.length > 1
      @getMutilpleItemMenu fileViews
    else
      [fileView] = fileViews
      switch fileView.getData().type
        when 'machine'    then @getMachineMenu fileView
        when 'file'       then @getFileMenu fileView
        when 'folder'     then @getFolderMenu fileView
        when 'mount'      then @getMountMenu fileView
        when 'brokenLink' then @getBrokenLinkMenu fileView
        # when "section" then @getSectionMenu fileData

  getContextMenu: (fileViews, event) ->

    @contextMenu.destroy() if @contextMenu
    items = @getMenuItems fileViews
    [fileView] = fileViews
    if items
      @contextMenu = new KDContextMenu
        event    : event
        delegate : fileView
        cssClass : 'finder'
      , items
      @contextMenu.on 'ContextMenuItemReceivedClick', (contextMenuItem) =>
        @handleContextMenuClick fileView, contextMenuItem
      return @contextMenu
    else
      return no

  destroyContextMenu: ->
    @contextMenu.destroy()

  handleContextMenuClick: (fileView, contextMenuItem) ->

    @emit 'ContextMenuItemClicked', { fileView, contextMenuItem }

  getFileMenu: (fileView) ->

    fileData = fileView.getData()

    items =
      'Open file'                 :
        separator                 : yes
        action                    : 'openFile'
      'Watch file'                 :
        separator                 : yes
        action                    : 'tailFile'
      # 'Open with...'              :
      #   children                  : @getOpenWithMenuItems fileView
      Delete                      :
        action                    : 'delete'
        separator                 : yes
      Rename                      :
        action                    : 'rename'
      Duplicate                   :
        action                    : 'duplicate'
      'Set permissions'           :
        children                  :
          customView              : new NSetPermissionsView {}, fileData
      Extract                     :
        action                    : 'extract'
      Compress                    :
        separator                 : yes
        children                  :
          'as .zip'               :
            action                : 'zip'
          'as .tar.gz'            :
            action                : 'tarball'
      # Download                    :
      #   separator                 : yes
      #   action                    : 'download'
      #   disabled                  : yes
      # 'Public URL...'             :
      #
      'New file'                  :
        separator                 : yes
        action                    : 'createFile'
      'New folder'                :
        action                    : 'createFolder'

    if 'archive' isnt FSHelper.getFileType FSHelper.getFileExtension fileData.name
      delete items.Extract
    else
      delete items.Compress

    # unless FSHelper.isPublicPath fileData.path
    #   delete items['Public URL...']
    # else
    #   items['Public URL...'].children =
    #     customView : new NCopyUrlView {}, fileData

    return items


  getFolderMenu: (fileView) ->

    fileData = fileView.getData()

    items =
      Expand                      :
        action                    : 'expand'
        separator                 : yes
      Collapse                    :
        action                    : 'collapse'
        separator                 : yes
      # 'Open with...'              :
      #   children                  : @getOpenWithMenuItems fileView
      'Make this the top folder'  :
        action                    : 'makeTopFolder'
        separator                 : yes
      Delete                      :
        action                    : 'delete'
        separator                 : yes
      Rename                      :
        action                    : 'rename'
      Duplicate                   :
        action                    : 'duplicate'
      Compress                    :
        children                  :
          'as .zip'               :
            action                : 'zip'
          'as .tar.gz'            :
            action                : 'tarball'
      'Set permissions'           :
        separator                 : yes
        children                  :
          customView              : new NSetPermissionsView {}, fileData
      'New file'                  :
        action                    : 'createFile'
      'New folder'                :
        action                    : 'createFolder'
      # 'Upload file...'            :
      #   action                    : 'upload'
      # 'Clone a repo here'         :
      #   action                    : "cloneRepo"
      #   separator                 : yes
      # Download                    :
      #   disabled                  : yes
      #   action                    : "download"
      #   separator                 : yes
      # 'Public URL...'             :
      #   separator                 : yes
      Refresh                     :
        action                    : 'refresh'

    if fileView.expanded
      delete items.Expand
    else
      delete items.Collapse

    # unless FSHelper.isPublicPath fileData.path
    #   delete items['Public URL...']
    # else
    #   items['Public URL...'].children =
    #     customView : new NCopyUrlView {}, fileData

    # {nickname} = KD.whoami().profile

    # if ///\/home\/#{nickname}\/Applications$///.test fileData.path
    #   items.Refresh.separator         = yes
    #   items["Make a new Application"] =
    #     action : "makeNewApp"

    # if fileData.getExtension() is "kdapp"
    #   items.Refresh.separator   = yes
    #   items['Application menu'] =
    #     children                   :
    #       Compile                  :
    #         action                 : "compile"
    #       "Publish to app catalog" :
    #         action                 : "publish"
    # else
    #   delete items['Open with...']

    return items

  getBrokenLinkMenu: (fileView) ->

    fileData   = fileView.getData()
    items      =
      Delete   :
        action : 'delete'

    items

  getMachineMenu: (fileView) ->

    fileData = fileView.getData()

    items =
      Refresh                     :
        action                    : 'refresh'
        separator                 : yes
      # 'Unmount VM'                :
      #   action                    : 'unmountVm'
      # 'Open terminal'             :
      #   action                    : 'openMachineTerminal'
      #   separator                 : yes
      Expand                      :
        action                    : 'expand'
        separator                 : yes
      Collapse                    :
        action                    : 'collapse'
        separator                 : yes
      'Change top folder'         :
        separator                 : yes
        children                  : @getTopFolderItems fileView
      'New file'                  :
        action                    : 'createFile'
      'New folder'                :
        action                    : 'createFolder'
        separator                 : yes
      'Toggle invisible files'    :
        action                    : 'toggleDotFiles'
      # 'Upload file...'            :
      #   action                    : 'upload'

    if fileView.expanded
    then delete items.Expand
    else delete items.Collapse

    return items

  getTopFolderItems: (fileView) ->
    currentPath = FSHelper.plainPath fileView.getData().path
    nickname    = nick()
    parents     = []
    nodes       = currentPath.split '/'

    for x in [ 0...nodes.length ]
      nodes = currentPath.split '/'
      path  = nodes.splice(1, x).join '/'
      parents.push "/#{path}"

    parents  = _.uniq parents.reverse()
    items    = {}
    root     = "/home/#{nick()}/"
    fileData = fileView.getData()
    finder   = fileData.treeController.getDelegate()

    parents.forEach (path) =>
      if path
        label = path.replace root, '~/'
        items[label] = { callback : =>
          finder?.updateMachineRoot fileData.machine.uid, path
          @contextMenu.destroy()
        }

    return items

  getMountMenu: (fileView) ->

    fileData = fileView.getData()

    items =
      Refresh                     :
        action                    : 'refresh'
        separator                 : yes
      Expand                      :
        action                    : 'expand'
        separator                 : yes
      Collapse                    :
        action                    : 'collapse'
        separator                 : yes
      'New file'                  :
        action                    : 'createFile'
      'New folder'                :
        action                    : 'createFolder'
      'Upload file...'            :
        action                    : 'upload'

    if fileView.expanded
      delete items.Expand
    else
      delete items.Collapse

    return items

  getMutilpleItemMenu: (fileViews) ->

    types =
      file    : no
      folder  : no
      mount   : no

    for fileView in fileViews
      types[fileView.getData().type] = yes

    if types.file and not types.folder and not types.mount
      return @getMultipleFileMenu fileViews

    else if not types.file and types.folder and not types.mount
      return @getMultipleFolderMenu fileViews

    items =

      Delete                      :
        action                    : 'delete'
        separator                 : yes
      Duplicate                   :
        action                    : 'duplicate'
      Compress                    :
        children                  :
          'as .zip'               :
            action                : 'zip'
          'as .tar.gz'            :
            action                : 'tarball'
      # Download                    :
      #   disabled                  : yes
      #   action                    : 'download'

    return items

  getMultipleFolderMenu: (folderViews) ->

    items =
      Expand            :
        action          : 'expand'
        separator       : yes
      Collapse          :
        action          : 'collapse'
        separator       : yes
      Delete            :
        action          : 'delete'
        separator       : yes
      Duplicate         :
        action          : 'duplicate'
      'Set permissions' :
        children        :
          customView    : (new NSetPermissionsView {}, { mode : '000', type : 'multiple' })
      Compress          :
        children        :
          'as .zip'     :
            action      : 'zip'
          'as .tar.gz'  :
            action      : 'tarball'
      # Download          :
      #   disabled        : yes
      #   action          : 'download'

    multipleText = "Delete #{folderViews.length} folders"
    items.Delete = items[multipleText] =
      action    : 'delete'

    allCollapsed = allExpanded = yes
    for folderView in folderViews
      if folderView.expanded then allCollapsed = no
      else allExpanded = no

    delete items.Collapse if allCollapsed
    delete items.Expand if allExpanded

    return items

  getMultipleFileMenu: (fileViews) ->

    items =
      'Open files'      :
        action          : 'openFile'
      Delete            :
        action          : 'delete'
        separator       : yes
      Duplicate         :
        action          : 'duplicate'
      'Set permissions' :
        children        :
          customView    : (new NSetPermissionsView {}, { mode : '000' })
      Compress          :
        children        :
          'as .zip'     :
            action      : 'zip'
          'as .tar.gz'  :
            action      : 'tarball'
      # Download          :
      #   disabled        : yes
      #   action          : 'download'

    multipleText = "Delete #{fileViews.length} files"
    items.Delete = items[multipleText] =
      action    : 'delete'

    return items

  getOpenWithMenuItems: (fileView) ->
    items            = {}
    reWebHome        = /// \/home\/#{nick()}\/Web/ ///

    { path, type }     = fileView.getData()
    plainPath        = FSHelper.plainPath path
    fileExtension    = FSHelper.getFileExtension path

    # FIXME: Add this ability later ~ GG
    # appsController   = KD.singleton "kodingAppsController"
    # {extensionToApp} = appsController
    # possibleApps     = (extensionToApp[fileExtension] or extensionToApp.txt) or []
    # for appName in possibleApps
    #   items[appName] = action: "openFileWithApp"

    items['Viewer']               = { action   : 'previewFile' }  if plainPath.match reWebHome
    if fileExtension is 'kdapp' and type is 'folder'
      items['DevTools']           = { action   : 'openFileWithApp' }

    items['separator']            = { type     : 'separator' }
    items['Other apps']           = { disabled : yes } # action   : "showOpenWithModal", separator : yes
    items['Search the app store'] = { disabled : yes }

    return items

# this is shorter but needs coffee script update

# 'Open File'                 : action : 'openFile'
# 'Open with...'              :
#   children                  :
#     'Ace Editor'            : action : 'openFile'
#     'CodeMirror'            : action : 'openFileWithCodeMirror'
#     'Viewer'                : action : 'previewFile'
#     divider                 : yes
#     'Search the App Store'  : disabled : yes
#     'Contribute an Editor'  : disabled : yes
# divider                     : yes
# Delete                      : action : 'delete'
# divider                     : yes
# Rename                      : action : 'rename'
# Duplicate                   : action : 'duplicate'
# 'Set permissions'           :
#   children                  :
#     customView              : KDView
# Extract                     : action : 'extract'
# Compress                    :
#   children                  :
#     'as .zip'               :
#       action                : 'zip'
#     'as .tar.gz'            :
#       action                : 'tarball'
# Download                    : action : 'download'
# divider                     : yes
# 'New File'                  : action : 'createFile'
# 'New Folder'                : action : 'createFolder'
# 'Upload file...'            : action : 'upload', disabled : yes
# 'Clone from Github...'      : action : 'gitHubClone', disabled : yes
