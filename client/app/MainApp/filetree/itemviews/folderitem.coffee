class NFolderItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass  or= "folder"
    super options, data

    # data.on "fs.chmod.finished", (recursive)=>
    #   warn "todo : refresh folder" if recursive


    # FIXME GG Remove that here use watcher features instead
    {nickname} = KD.whoami().profile

    if data.type is 'folder' and (/\.kdapp$/.test data.path) or \
       ///#{nickname}\/Applications$///.test data.path

      data.on "fs.delete.finished", =>
        @getSingleton("kodingAppsController").refreshApps()
