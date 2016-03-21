kd                    = require 'kd'
JTreeItemView         = kd.JTreeItemView
KDProgressBarView     = kd.ProgressBarView
FSHelper              = require 'app/util/fs/fshelper'
NBrokenLinkItemView   = require './nbrokenlinkitemview'
NFileItemView         = require './nfileitemview'
NFinderItemDeleteView = require '../itemsubviews/nfinderitemdeleteview'
NFinderItemRenameView = require '../itemsubviews/nfinderitemrenameview'
NFolderItemView       = require './nfolderitemview'
NMachineItemView      = require './nmachineitemview'
NMountItemView        = require './nmountitemview'
NSectionItemView      = require './nsectionitemview'


module.exports = class NFinderItem extends JTreeItemView

  constructor: (options = {}, data) ->

    options.tagName or= 'li'
    options.type    or= 'finderitem'

    super options, data

    @isLoading        = no
    @beingDeleted     = no
    @beingEdited      = no
    @beingProgress    = no

    childConstructor = @getChildConstructor data.type

    @childView = new childConstructor { delegate: this }, data
    @childView.$().css 'margin-left', (data.depth) * 14

    if data.name? and data.name.length > 20 - data.depth
      @childView.setAttribute 'title', FSHelper.plainPath data.name

    @on 'ItemBeingDeleted', ->
      data.removeLocalFileInfo()


  getChildConstructor: (type) ->
    switch type
      when 'machine'    then NMachineItemView
      when 'folder'     then NFolderItemView
      when 'section'    then NSectionItemView
      when 'mount'      then NMountItemView
      when 'brokenLink' then NBrokenLinkItemView
      else NFileItemView

  mouseDown: -> yes

  resetView: (view) ->

    if @deleteView
      @deleteView.destroy()
      delete @deleteView

    if @renameView
      @renameView.destroy()
      delete @renameView

    if @progressView
      @progressView.unsetTooltip()
      @progressView.destroy()
      delete @progressView

    @childView.show()
    @beingDeleted  = no
    @beingEdited   = no
    @beingProgress = no
    @callback      = null
    @unsetClass 'being-deleted being-edited progress'
    @getDelegate().setKeyView()

  confirmDelete: (callback) ->

    @callback = callback
    @showDeleteView()

  showDeleteView: ->

    return if @deleteView
    @setClass 'being-deleted'
    @beingDeleted = yes
    @childView.hide()
    data = @getData()
    @addSubView @deleteView = new NFinderItemDeleteView {}, data
    @deleteView.on 'FinderDeleteConfirmation', (confirmation) =>
      @callback? confirmation
      @resetView()
    @deleteView.setKeyView()

  showRenameView: (callback) ->

    return  if @renameView

    @setClass 'being-edited'

    @beingEdited = yes
    @callback    = callback
    data         = @getData()

    @childView.hide()

    @addSubView @renameView = new NFinderItemRenameView {}, data
    @renameView.$().css 'margin-left', ((data.depth + 1) * 10) + 2

    @renameView.on 'FinderRenameConfirmation', (newValue) =>
      @callback? newValue
      @resetView()

    ext       = ".#{FSHelper.getFileExtension data.name}"
    { input } = @renameView

    if (index = data.name.indexOf ext) > 0
      input.getElement().setSelectionRange 0, index

    input.setFocus()


  showProgressView: (progress, determinate = yes) ->

    { loaded, total, percent } = progress

    unless @progressView
      @addSubView @progressView = new KDProgressBarView

    @progressView.setOption 'determinate', determinate
    @progressView.updateBar percent, '%', ''

    if loaded? and total?
      title = "#{loaded}mb of #{total}mb uploaded"
      unless @progressView.tooltip?
        @progressView.setTooltip { title }
      else
        @progressView.tooltip.setTitle title
    else
      @progressView.unsetTooltip()

    if 0 <= percent < 100
    then @setClass 'progress'
    else kd.utils.wait 1000, @bound 'resetView'

  viewAppended: ->

    @addSubView @childView

    file = @getData()
    fileInfo = file.getLocalFileInfo()

    if fileInfo.lastUploadedChunk

      { lastUploadedChunk, totalChunks } = fileInfo

      if lastUploadedChunk is totalChunks
        file.removeLocalFileInfo()

      @showProgressView
        percentage : 100 * lastUploadedChunk / totalChunks
