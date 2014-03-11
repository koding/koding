class OnboardingItemView extends CustomViewsDashboardView

  constructor: (options = {}, data) ->

    super options, data

    labelText = ""

    if data.isActive then labelText = "Published"
    else if data.isPreview
    then labelText   = "On preview"

    @title           = new KDCustomHTMLView
      tagName        : "h3"
      cssClass       : options.cssClass
      partial        : "#{options.title} <span>#{labelText}</span>"

    @addNewButton    = new KDButtonViewWithMenu
      title          : ""
      icon           : yes
      delegate       : this
      iconClass      : "settings"
      cssClass       : "settings-menu"
      itemChildClass : OnboardingSettingsMenuItem
      style          : "resurrection"
      menu           : @getMenuItems()

    @loader.on "viewAppended", =>
      @loader.hide()

    @on "DeleteChildItem", (childData) =>
      @deleteChildItem childData

  getMenuItems: ->
    data         = @getData()
    activeLabel  = if data.isActive  then "Unpublish"      else "Publish"
    previewLabel = if data.isPreview then "Cancel preview" else "Preview"
    items        =
      "Add Into" : callback: => @addNew()
      "Edit"     : callback: => @edit()
      "Delete"   : callback: => @delete()

    items[activeLabel]  = callback : => @updateState "isActive"
    items[previewLabel] = callback : => @updateState "isPreview"

    return items

  updateState: (key) ->
    changeSet = {}
    data      = @getData()
    callback  = =>
      changeSet[key] = not data[key]
      data.update changeSet, (err, res) =>
        return warn err  if err
        @getDelegate().reloadViews()

    keyword = "publish"

    if key is "isActive"
      if data[key] then keyword = "unpublish"
    else
      keyword = if data[key] then "cancel preview for" else "enable preview mode for"

    content        = "Are you sure you want to #{keyword} this item?"
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

  fetchViews: ->
    @loader.hide()
    {items} = @getData().partial
    return @noViewLabel.show()  if items?.length is 0
    @createList items

  createList: (items) ->
    return  unless items
    for item in items
      itemView = new OnboardingChildItem { delegate: this }, item
      @customViews.push itemView
      @container.addSubView itemView

  deleteChildItem: (childData) ->
    data    = @getData()
    {items} = data.partial
    for item in items when item.name is childData.name
      items.splice items.indexOf(item), 1
      break

    data.update { "partial.items": items }, (err, res) =>
      return warn err  if err
      @addNewButton.show()
      @reloadViews()

  edit: ->
    @hideViews()
    @addSubView new OnboardingSectionForm { delegate: @getDelegate() }, @getData()

  delete: ->
    @confirmDelete =>
      @getData().remove (err, res) =>
        return warn err  if err
        @getDelegate().container.destroySubViews()
        @getDelegate().reloadViews()

  confirmDelete: (callback = noop) ->
    modal          = new KDModalView
      title        : "Are you sure?"
      content      : "Are you sure you want to delete the item. This cannot be undone."
      overlay      : yes
      buttons      :
        Delete     :
          title    : "Delete"
          cssClass : "modal-clean-red"
          callback : =>
            callback()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()


class OnboardingChildItem extends CustomViewItem

  delete: ->
    @getDelegate().emit "DeleteChildItem", @getData()


class OnboardingSettingsMenuItem extends JView

  pistachio :->
    {title} = @getData()
    """
      <i class="#{KD.utils.slugify title} icon"></i>#{title}
    """