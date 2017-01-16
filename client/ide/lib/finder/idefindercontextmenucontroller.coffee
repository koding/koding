NFinderContextMenuController = require 'finder/filetree/controllers/nfindercontextmenucontroller'
NSetPermissionsView          = require 'finder/filetree/itemsubviews/nsetpermissionsview'


module.exports = class IDEFinderContextMenuController extends NFinderContextMenuController


  getFolderMenu: (fileView) ->

    fileData = fileView.getData()

    items =
      Expand                      :
        action                    : 'expand'
        separator                 : yes
      Collapse                    :
        action                    : 'collapse'
        separator                 : yes
      'Change top folder'         :
        separator                 : yes
        children                  : @getTopFolderItems fileView
      'Make this the top folder'  :
        action                    : 'makeTopFolder'
      'Terminal from here'        :
        action                    : 'createTerminal'
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
      Refresh                     :
        action                    : 'refresh'

    if fileView.expanded
      delete items.Expand
    else
      delete items.Collapse

    return items
