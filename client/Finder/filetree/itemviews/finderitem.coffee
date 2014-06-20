class NFinderItem extends JTreeItemView

  JView.mixin @prototype

  constructor:(options = {},data)->

    options.tagName or= "li"
    options.type    or= "finderitem"

    super options, data

    @isLoading        = no
    @beingDeleted     = no
    @beingEdited      = no
    @beingProgress    = no

    childConstructor = switch data.type
      when "machine"    then NMachineItemView
      when "folder"     then NFolderItemView
      when "section"    then NSectionItemView
      when "mount"      then NMountItemView
      when "brokenLink" then NBrokenLinkItemView
      else NFileItemView

    @childView = new childConstructor delegate: this, data
    @childView.$().css "margin-left", (data.depth) * 14

    if data.name? and data.name.length > 20 - data.depth
      @childView.setAttribute "title", FSHelper.plainPath data.name

    @on "ItemBeingDeleted", =>
      data.removeLocalFileInfo()

    @on "viewAppended", =>
      fileInfo = data.getLocalFileInfo()
      if fileInfo.lastUploadedChunk
        {lastUploadedChunk, totalChunks} = fileInfo
        data.removeLocalFileInfo() if lastUploadedChunk is totalChunks
        @showProgressView 100 * lastUploadedChunk / totalChunks

  mouseDown:-> yes

  resetView:(view)->

    if @deleteView
      @deleteView.destroy()
      delete @deleteView

    if @renameView
      @renameView.destroy()
      delete @renameView

    if @progressView
      @progressView.destroy()
      delete @progressView

    @childView.show()
    @beingDeleted  = no
    @beingEdited   = no
    @beingProgress = no
    @callback      = null
    @unsetClass "being-deleted being-edited progress"
    @getDelegate().setKeyView()

  confirmDelete:(callback)->

    @callback = callback
    @showDeleteView()

  showDeleteView:->

    return if @deleteView
    @setClass "being-deleted"
    @beingDeleted = yes
    @childView.hide()
    data = @getData()
    @addSubView @deleteView = new NFinderItemDeleteView {}, data
    @deleteView.on "FinderDeleteConfirmation", (confirmation)=>
      @callback? confirmation
      @resetView()
    @deleteView.setKeyView()

  showRenameView:(callback)->

    return if @renameView
    @setClass "being-edited"
    @beingEdited = yes
    @callback = callback
    @childView.hide()
    data = @getData()
    @addSubView @renameView = new NFinderItemRenameView {}, data
    @renameView.$().css "margin-left", ((data.depth+1)*10)+2
    @renameView.on "FinderRenameConfirmation", (newValue)=>
      @callback? newValue
      @resetView()
    @renameView.input.setFocus()

  showProgressView: (percent=0, determinate=yes)->

    unless @progressView
      @addSubView @progressView = new KDProgressBarView

    @progressView.setOption "determinate", determinate
    @progressView.updateBar percent, "%", ""
    if 0 <= percent < 100
    then @setClass "progress"
    else @utils.wait 1000, =>
      @resetView()

  pistachio:->

    """
    {{> @childView}}
    """
