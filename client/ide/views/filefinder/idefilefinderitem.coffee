class IDE.FileFinderItem extends KDListItemView

  partial: ->
    {path}   = @getData()
    nicePath = path.replace "/home/#{KD.nick()}", '~'
    fileName = FSHelper.getFileNameFromPath path

    return """
      <p class="name">#{fileName}</p>
      <p class="path">#{nicePath}</p>
    """

  click: ->
    @emit 'FileNeedsToBeOpened', @getData().path
