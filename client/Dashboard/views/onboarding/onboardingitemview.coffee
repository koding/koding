class OnboardingItemView extends CustomViewsDashboardView

  constructor: (options = {}, data) ->

    super options, data

    @addNewButton = new KDButtonViewWithMenu
      title          : ""
      icon           : yes
      delegate       : this
      iconClass      : "settings"
      cssClass       : "settings-menu"
      itemChildClass : OnboardingSettingsMenuItem
      menu           : @getMenuItems data

    @loader.on "viewAppended", =>
      @loader.hide()

    @on "DeleteChildItem", (childData) =>
      @deleteChildItem childData

  getMenuItems: ->
    return {
      "Add Into": callback: @bound "addNew"
      "Edit"    : callback: @bound "edit"
      "Delete"  : callback: @bound "delete"
    }

  fetchViews: ->
    @loader.hide()
    {items} = @getData().partial
    return @noViewLabel.show()  if items.length is 0
    @createList items

  createList: (items) ->
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
    @addNew {}, @getData()

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