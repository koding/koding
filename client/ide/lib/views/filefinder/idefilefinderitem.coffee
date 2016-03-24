kd = require 'kd'
KDListItemView = kd.ListItemView
nick = require 'app/util/nick'
FSHelper = require 'app/util/fs/fshelper'
module.exports = class IDEFileFinderItem extends KDListItemView

  partial: ->
    { path } = @getData()
    nicePath = path.replace "/home/#{nick()}", '~'
    fileName = FSHelper.getFileNameFromPath path

    return """
      <p class="name">#{fileName}</p>
      <p class="path">#{nicePath}</p>
    """

  click: ->
    @emit 'FileNeedsToBeOpened', @getData().path
