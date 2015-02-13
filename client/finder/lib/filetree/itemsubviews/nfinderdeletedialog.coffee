kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
KDScrollView = kd.ScrollView
module.exports = class NFinderDeleteDialog extends KDModalView

  constructor:(options = {},data)->

    items            = data.items
    callback         = data.callback
    numFiles         = "#{items.length} item#{if items.length > 1 then 's' else ''}"
    options.title    = "Do you really want to delete #{numFiles}"
    options.content  = ""
    options.overlay  = yes
    options.cssClass = "new-kdmodal"
    options.width    = 500
    options.height   = "auto"
    options.buttons  = {}
    options.buttons["Yes, delete #{numFiles}"] =
      style         : "modal-clean-red"
      callback      : =>
        callback? yes
        @destroy()
    options.buttons.cancel =
      style         : "modal-cancel"
      callback      : =>
        callback? no
        @destroy()
    super options, data
    kd.getSingleton("windowController").setKeyView null

  viewAppended:->

    {items} = @getData()
    @$().css top : 75

    scrollView = new KDScrollView
      cssClass    : 'modalformline file-container'
    scrollView.$().css maxHeight : kd.getSingleton('windowController').winHeight - 250

    for item in items
      scrollView.addSubView fileView = new KDCustomHTMLView
        tagName   : 'p'
        cssClass  : "delete-file #{item.getData().type}"
        partial   : "<span class='icon'></span>#{item.getData().name}"

    @addSubView scrollView

  destroy:->
    kd.getSingleton("windowController").revertKeyView()
    super

