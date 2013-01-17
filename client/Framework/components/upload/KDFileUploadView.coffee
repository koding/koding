#####
# File Upload class, consists of
# - a KDView for upload area
# - n KDInputViews
# - a KDListView to list files after drop
# - n KDListItemViews
#####
#
# options:
#   limit        : 1            -> number of max amount of files to be sent to server
#   preview      : "thumbs"     -> thumbs or list
#   extensions   : null         -> allowed extensions e.g. ["png","jpg","gif"]
#   fileMaxSize  : 0            -> max number in kilobytes for each file size
#   totalMaxSize : 0            -> max number in kilobytes for sum of all file sizes
#   title        : String       -> a title which will appear in droppable area
#
# NOTE: since it creates input fields with filedata it should be added to forms
#####

class KDFileUploadView extends KDView
  constructor:(options,data)->
    if window.FileReader?
      options.limit         ?= 20
      options.fileMaxSize   ?= 4096
      options.filetotalSize ?= 4096
      options.extensions    ?= null
      options.preview       ?= "list"
      options.title         ?= "Drop your files here!"
      super options,data
      @listController = null
      @addDropArea()
      @addList()
      @files = {}
      @listenTo
        KDEventTypes        : "FileReadComplete"
        listenedToInstance  : @
        callback            : @fileReadComplete
      @totalSizeToUpload = 0
      @setClass "kdfileupload"
    else
      super options,data
      @setPartial "<p class='warning info'><strong>Oops sorry,</strong> file upload is only working on Chrome, Firefox and Opera at the moment. We're working on a fix.</p>"

  addDropArea:()->
    @dropArea = new KDFileUploadArea
      title    : @getOptions().title
      bind     : 'drop dragenter dragleave dragover dragstart dragend'
      cssClass : "kdfileuploadarea"
      delegate : @
    @addSubView @dropArea

  addList:()->
    @fileList = switch @getOptions().preview
      when "thumbs" then do @addThumbnailList
      else do @addFileList

    @listController = new KDListViewController
      view : @fileList

    @addSubView @listController.getView()

  addFileList:()-> new KDFileUploadListView delegate : @
  addThumbnailList:()-> new KDFileUploadThumbListView delegate : @

  fileDropped:(file)->
    reader = new FileReader()
    reader.onload = (event)=>
      @propagateEvent KDEventType : "FileReadComplete", {progressEvent : event, file : file}
      @emit "FileReadComplete", {progressEvent : event, file : file}

    reader.readAsDataURL file

  fileReadComplete:(pubInst,event)->
    file = event.file
    file.data = event.progressEvent.target.result
    @putFileInQueue file

  putFileInQueue:(file)->
    if not @isDuplicate(file) and @checkLimits(file)
      @files[file.name] = file
      @fileList.addItem file
      return yes
    else
      return no

  removeFile:(pubInst,event)->
    file = pubInst.getData()
    delete @files[file.name]
    @fileList.removeItem pubInst

  isDuplicate:(file)->
    if @files[file.name]?
      @notify "File is already in queue!"
      yes
    else
      no

  checkLimits:(file)->
    return @checkFileAmount() and @checkFileSize(file) and @checkTotalSize(file)

  checkFileAmount:()->
    maxAmount  = @getOptions().limit
    amount = 1
    for own name,file of @files
      amount++
    if amount > maxAmount
      @notify "Total number of allowed file is #{maxAmount}"
      no
    else
      yes

  checkTotalSize:(file)->
    totalMaxSize  = @getOptions().totalMaxSize
    totalSize = file.size
    for own name,file of @files
      totalSize += file.size

    if totalSize/1024 > totalMaxSize
      @notify "Total allowed filesize is #{totalMaxSize} kilobytes"
      no
    else
      yes

  checkFileSize:(file)->
    fileMaxSize = @getOptions().fileMaxSize
    if file.size/1024 > fileMaxSize
      @notify "Maximum allowed filesize is #{fileMaxSize} kilobytes"
      no
    else
      yes

  notify:(title)->
    new KDNotificationView
      title   : title
      duration: 2000
      type    : "tray"

class KDFileUploadArea extends KDView
  # isDroppable:()->
  #   return @droppingEnabled ? yes
  #
  # dropAccept:(item)=>
  #   yes
  #
  # dropOver:(event,ui)=>
  #   event.preventDefault()
  #   event.stopPropagation()
  #   @setClass "hover"
  #
  # dropOut:(event,ui)=>
  #   event.preventDefault()
  #   event.stopPropagation()
  #   @unsetClass "hover"

  dragEnter:(e)->
    e.preventDefault()
    e.stopPropagation()
    @setClass "hover"

  dragOver:(e)->
    e.preventDefault()
    e.stopPropagation()
    @setClass "hover"

  dragLeave:(e)->
    e.preventDefault()
    e.stopPropagation()
    @unsetClass "hover"

  drop:(jQueryEvent)->
    jQueryEvent.preventDefault()
    jQueryEvent.stopPropagation()
    @unsetClass "hover"

    orgEvent = jQueryEvent.originalEvent

    files = orgEvent.dataTransfer.files

    for file in files
      @getDelegate().fileDropped file
    no

  viewAppended:()->
    title = @getOptions().title
    o = @getDelegate().getOptions()
    @setPartial "<span>#{title}</span>"
    @addSubView new KDCustomHTMLView
      cssClass    : "info"
      tagName     : "span"
      tooltip     :
        title     : "Max. File Amount: <b>#{o.limit}</b> files<br/>Max. File Size: <b>#{o.fileMaxSize}</b> kbytes<br/>Max. Total Size: <b>#{o.totalMaxSize}</b> kbytes"
        placement : "above"
        offset    : 0
        delayIn   : 300
        html      : yes
        animate   : yes
        selector  : null
        partial   : "i"

    # TIPTIP DEPRECATED
    # @$().find("span.iconic").tipTip defaultPosition : "top"


class KDFileUploadListView extends KDListView
  constructor:(options,data)->
    super options,data
    @setClass "kdfileuploadlist"

  addItem:(file)->
    itemInstance = new KDKDFileUploadListItemView {delegate : @},file
    @getDelegate().listenTo
      KDEventTypes:
        eventType:        "removeFile"
      listenedToInstance: itemInstance
      callback:           @getDelegate().removeFile
    @addItemView itemInstance

class KDKDFileUploadListItemView extends KDListItemView
  constructor:(options,data)->
    super options,data
    @setClass "kdfileuploadlistitem clearfix"
    @active = no

  click:(e)->
    @handleEvent {type : "removeFile", orgEvent : e} if $(e.target).is "span.iconic.x"

  viewAppended:()->
    @$().append @partial @data

  partial:(file)->
    $ "<span class='file-title'>#{file.name}</span>
       <span class='file-size'>#{(file.size / 1024).toFixed(2)}kb</span>
       <span class='x'></span>"

class KDFileUploadThumbListView extends KDListView
  constructor:(options,data)->
    super options,data
    @setClass "kdfileuploadthumblist"

  addItem:(file)->
    itemInstance = new KDFileUploadThumbItemView {delegate : @},file
    @getDelegate().listenTo
      KDEventTypes:
        eventType:        "removeFile"
      listenedToInstance: itemInstance
      callback:           @getDelegate().removeFile
    @addItemView itemInstance

class KDFileUploadThumbItemView extends KDListItemView
  constructor:(options,data)->
    super options,data
    @setClass "kdfileuploadthumbitem clearfix"
    @active = no

  click:(e)->
    @handleEvent {type : "removeFile", orgEvent : e} if $(e.target).is "span.close-icon"

  viewAppended:()->
    @$().append @partial @data
    # @addSubView new KDInputView
    #   type          : "hidden"
    #   name          : "file-name"
    #   defaultValue  : @data.name
    # @addSubView new KDInputView
    #   type          : "hidden"
    #   name          : "file-data"
    #   defaultValue  : @data.data


  partial:(file)->
    log file
    imageType = /image.*/
    fileUrl = if file.type.match imageType then window.URL.createObjectURL file else "./images/icon.file.png"

    $ "<img class='thumb' src='#{fileUrl}'/>
       <p class='meta'>
        <span class='file-title'>#{file.name}</span>
        <span class='file-size'>#{(file.size / 1024).toFixed(2)}kb</span>
        <span class='close-icon'></span>
       </p>"
