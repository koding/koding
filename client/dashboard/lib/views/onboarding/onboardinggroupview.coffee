kd = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
CustomViewsDashboardView = require '../customviews/customviewsdashboardview'
OnboardingChildItem = require '../../onboardingchilditem'
OnboardingSectionForm = require './onboardingsectionform'
OnboardingSettingsMenuItem = require '../../onboardingsettingsmenuitem'


module.exports = class OnboardingGroupView extends CustomViewsDashboardView

  ###*
   * View that renders onboarding group and its onboarding items
  ###
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


  ###*
   * Returns a hash object with actions for onboarding group and corresponding action handlers
   *
   * @return {object<string,function>}
  ###
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


  ###*
   * Once user publishes onboarding group or sets it on preview mode or turns off those flags,
   * it updates a state of group in DB and reloads a list of onboardings after it
   * Before changing the state it's necessary to confirm the action from user
   *
   * @param {string} key - a field of JCustomPartial object which should be toggled. Possible values are 'isActive' (to publish/unpublish onboarding)
   * and 'isPreview' (to set/unset on preview mode)
   * @emits SectionSaved
  ###
  updateState: (key) ->

    changeSet = {}
    data      = @getData()
    callback  = =>
      changeSet[key] = not data[key]
      data.update changeSet, (err, res) =>
        return kd.warn err  if err
        @emit 'SectionSaved'

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


  ###*
   * Overrides base method
   * Since we already have onboarding items in onboarding group data,
   * it's not needed to fetch them from the server - we can render them immediately
  ###
  fetchViews: ->

    @loader.hide()
    {items} = @getData().partial
    return @noViewLabel.show()  if items?.length is 0
    @createList items


  ###*
   * Overrides base method
   * Removes onboarding item from onboarding group, updates DB
   * and reloads a list of onboarding items
   *
   * @return {object} - data of deleting onboarding item view
  ###
  handleViewDeleted: (childData) ->

    data    = @getData()
    {items} = data.partial
    for item in items when item.name is childData.name
      items.splice items.indexOf(item), 1
      break

    data.update { "partial.items": items }, (err, res) =>
      return kd.warn err  if err
      @addNewButton.show()
      @reloadViews()


  ###*
   * Shows onboarding group edit form when user performs 'Edit' action
   * and binds to form events. Onboarding items become invisible
  ###
  edit: ->

    @hideViews()
    sectionForm = new OnboardingSectionForm {}, @getData()
    @forwardEvent sectionForm, 'SectionSaved'
    sectionForm.on 'SectionCancelled', @bound 'cancel'
    @addSubView sectionForm


  ###*
   * Deletes onboarding group when user performs 'Delete' action
   * Before deleting the group it's necessary to confirm action from user
  ###
  delete: ->

    @confirmDelete =>
      @getData().remove (err, res) =>
        return kd.warn err  if err
        @emit 'SectionDeleted'

  ###*
   * Shows a confirmation modal when user performs delete action
   *
   * @param {function} callback - it's called when user confirms their action
  ###
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


  ###*
   * When user cancels editing onboarding group,
   * onboarding items should be shown again
   * and it's necessary to forward cancel event to parent view
  ###
  cancel: ->

    @showViews()
    @emit "SectionCancelled"