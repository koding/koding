class HomePageCustomViewItem extends CustomViewItem

  creteElements: ->
    super

    @previewToggle  = new KodingSwitch
      cssClass      : "dark preview-toggle"
      defaultValue  : @getData().isPreview
      settingType   : "preview"
      callback      : =>
        @confirmAction @previewToggle, =>
          @updateState "isPreview"

    @activateToggle = new KodingSwitch
      cssClass      : "dark publish"
      defaultValue  : @getData().isActive
      settingType   : "activate"
      callback      : =>
        @confirmAction @activateToggle, =>
          @updateState "isActive"

    @previewToggle.addSubView new KDCustomHTMLView
      tagName       : "span"
      partial       : "Preview"

    @activateToggle.addSubView new KDCustomHTMLView
      tagName       : "span"
      partial       : "Publish"

  confirmAction: (button, callback = noop) ->
    isActivated  = button.getValue()
    isPreview    = button.getOption("settingType") is "preview"

    if isActivated then button.setOff no else button.setOn no # don't update state, wait for confirmation

    content =
      if isPreview
        if isActivated then messages.enablePreview    else messages.cancelPreview
      else
        if isActivated then messages.enablePublishing else messages.cancelPublising

    modal          = new KDModalView
      title        : "Are you sure?"
      content      : "<p>#{content}</p>"
      overlay      : yes
      buttons      :
        Delete     :
          title    : "Confirm"
          cssClass : "modal-clean-green"
          callback : =>
            callback()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

  updateState: (key) ->
    delegate = @getDelegate()
    data     = @getData()

    for customView in delegate.customViews
      oldActive = customView  if customView.getData()[key] is yes

    toggleState = =>
      changeSet      = {}
      changeSet[key] = !data[key]

      data.update changeSet, (err, res) =>
        return warn err  if err
        delegate.reloadViews()

    if oldActive
      changeSet      = {}
      changeSet[key] = no

      oldActive.getData().update changeSet, (err, res) =>
        return warn err  if err
        toggleState()
    else
      toggleState()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      {{> @previewToggle}}
      {{> @activateToggle}}
      <div class="button-container">
        {{> @deleteButton}}
        {{> @editButton}}
      </div>
    """

  messages =
    cancelPreview   : """
      You are about to cancel preview mode for this item.
      If you don't have any preview enabled item, be sure you removed the preview cookie by pressing the CANCEL PREVIEW button.
    """
    enablePreview   : """
      You are about to preview this item.
      Bu sure, you already clicked the PREVIEW button to set the cookie.<br /><br />
      Incognito window won't work because it won't have a preview cookie unless you set one.<br /><br />
      Known issue: If you have a cookie, you will only see the selected preview item.
      Currently we won't show you already published item. Sorry for that :(
    """
    cancelPublising : """
      Are you sure you want to cancel publishing this item?
    """
    enablePublishing: """
      Are you sure you want to publish this item?
      It will be visible to ALL Koding members!
    """