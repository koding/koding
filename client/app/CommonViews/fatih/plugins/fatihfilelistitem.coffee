class FatihFileListItem extends KDListItemView

  constructor: (options = {}, data) ->
    options.tagName = "li"

    super options, data

  click: (event) ->
    KD.getSingleton('appManager').openFile FSHelper.createFileInstance path: @getData().path

    listView = @getDelegate()
    plugin   = listView.getDelegate()
    plugin.emit "ListItemClicked"

  partial: ->
    {path} = @getData()
    """
      <span class="icon file"></span>
      <span class="name">#{FSHelper.getFileNameFromPath path}</span>
      <span class="path">#{path}</span>
    """