class Finder extends KDTreeView

  makeItemDropTarget:(publishingInstance)->
    if publishingInstance instanceof KDTreeItemView
      $dropHelper = $ "<div/>"
        class   : "drop-helper"
        css     :
          height  : publishingInstance.getHeight()-6
          width   : publishingInstance.getDomElement().find(".title").width() + 40
      @removeAllDropHelpers()
      publishingInstance.getDomElement().prepend $dropHelper
    else
      warn "FIX: ",publishingInstance, "is not a KDTreeItemView, check event listeners!"

#FIXMERGE 12/12/11 -sah why are these duplicated from KDTreeView??
  scrollDown: ->
    unless @__scrollDownInitiated
      @__scrollDownInitiated = yes
      scroll = @$().closest(".kdscrollview > div")
      start = scroll.scrollTop()
      @__scrollDownInterval = setInterval =>
        scroll.scrollTop start = start + 12
      , 40
      
  deleteDialog: (items, callback) ->
    windowController = @getSingleton("windowController")
    finder = @
    windowController.setKeyView null
    numFiles = "#{items.length} file#{if items.length > 1 then 's' else ''}"
    options =
      title       : "Do you really want to delete #{numFiles}"
      content     : ""
      overlay     : yes
      cssClass    : "new-kdmodal"
      width       : 400
      height      : "auto"
      buttons     : {}

    options.buttons["Yes, delete " + numFiles] =
      style     : "modal-clean-red"
      callback  : ()->
        modal.destroy()
        windowController.setKeyView finder
        callback? yes
    options.buttons.cancel = 
      style     : "modal-cancel"
      callback  : ()->
        modal.destroy()
        windowController.setKeyView finder
        callback? no
        
    modal = new KDModalView options
    modal.$().css top : 75

    scrollView = new KDScrollView cssClass: 'modalformline'
    scrollView.$().css maxHeight : @getSingleton('windowController').winHeight - 250
        
    for item in items
      fileView = new KDCustomHTMLView tagName: 'p',cssClass: 'delete-file', partial: item.getData().name
      scrollView.addSubView fileView
    
    modal.addSubView scrollView, ".kdmodal-content"

  scrollUp: ->
    unless @__scrollUpInitiated
      @__scrollUpInitiated = yes
      scroll = @$().closest(".kdscrollview > div")
      start = scroll.scrollTop()
      @__scrollDownInterval = setInterval =>
        scroll.scrollTop start = start - 12
      , 40
      
  stopScroll: ->
    clearInterval @__scrollDownInterval
    @__scrollDownInitiated = no
    
    clearInterval @__scrollDownInterval
    @__scrollUpInitiated = no
    
  getTrickyWidth: () -> #saves width for some time, for too many requests
    unless @__trickyWidth
      @__trickyWidth = @getWidth()      
    else
      clearTimeout @__trickyWidthTimeout
      @__trickyWidthTimeout = setTimeout =>
        @__trickyWidth = null
      , 10
      
    return @__trickyWidth
    
  destroy: ->
    @emit 'destroy'
    super

  mouseDown:(event)->
    (@getSingleton "windowController").setKeyView @
    no
