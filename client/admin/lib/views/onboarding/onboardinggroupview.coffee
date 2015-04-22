kd = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
CustomViewsAdminView = require '../customviews/customviewsadminview'
OnboardingChildItem = require '../../onboardingchilditem'
OnboardingSectionForm = require './onboardingsectionform'
OnboardingSettingsMenuItem = require '../../onboardingsettingsmenuitem'


module.exports = class OnboardingGroupView extends CustomViewsAdminView

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
        return kd.warn err  if err
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
          cssClass : "solid green medium"
          callback : =>
            callback()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          cssClass : "solid light-gray medium"
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
      itemView.on 'ItemDeleted', @bound 'deleteChildItem'
      @customViews.push itemView
      @container.addSubView itemView


  deleteChildItem: (childData) ->

    data    = @getData()
    {items} = data.partial
    for item in items when item.name is childData.name
      items.splice items.indexOf(item), 1
      break

    data.update { "partial.items": items }, (err, res) =>
      return kd.warn err  if err
      @addNewButton.show()
      @reloadViews()


  edit: ->

    @hideViews()
    sectionForm = new OnboardingSectionForm {}, @getData()
    @forwardEvent sectionForm, 'SectionSaved'
    sectionForm.on 'SectionCancelled', @bound 'cancel'
    @addSubView sectionForm


  delete: ->

    @confirmDelete =>
      @getData().remove (err, res) =>
        return kd.warn err  if err
        @getDelegate().container.destroySubViews()
        @getDelegate().reloadViews()


  confirmDelete: (callback = kd.noop) ->

    modal          = new KDModalView
      title        : "Are you sure?"
      content      : "Are you sure you want to delete the item. This cannot be undone."
      overlay      : yes
      buttons      :
        Delete     :
          title    : "Delete"
          cssClass : "solid red medium"
          callback : =>
            callback()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          cssClass : "solid light-gray medium"
          callback : -> modal.destroy()


  cancel: ->

    @showViews()
    @emit "SectionCancelled"