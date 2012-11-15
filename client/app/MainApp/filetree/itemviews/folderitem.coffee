class NFolderItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass  or= "folder"
    super options, data

    data.on "fs.chmod.finished", (recursive)=>
      warn "todo : refresh folder" if recursive

    if data.getExtension() is "kdapp"
      data.on "fs.delete.finished", =>
        @getSingleton("kodingAppsController").refreshApps()

        # Thats for broken symlinks under application temp folder
        # Maybe we can change its place, keep it for now
        {nickname} = KD.whoami().profile
        KD.utils.removeBrokenSymlinksUnder "/Users/#{nickname}/Sites/#{nickname}.koding.com/website/.applications/"
