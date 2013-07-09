class AccountSshKeyListController extends KDListViewController
  constructor:(options,data)->
    super options,data

    @loadItems()

    @getListView().on "UpdatedItems", =>
      @newItem = no
      newKeys = @getItemsOrdered().map (item)-> item.getData()
      if newKeys.length is 0
        @addCustomItem "You have no SSH keys."
      else
        @customItem?.destroy()
      KD.remote.api.JUser.setSSHKeys newKeys, ->
        console.log "Saved keys."

    @getListView().on "RemoveItem", (item)=>
      @newItem = no
      @removeItem item
      @getListView().emit "UpdatedItems"

    @newItem = no

  loadItems: ()->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    KD.remote.api.JUser.getSSHKeys (keys)=>
      if keys.length > 0
        @instantiateListItems keys
      else
        @addCustomItem "You have no SSH keys."
      @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : =>
        unless @newItem
          @newItem = true
          @addItem {key: '', title: ''}, 0
          @getListView().items.first.swapSwappable()

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message

class AccountSshKeyList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data

class AccountSshKeyForm extends KDFormView

  constructor:->

    super

    @titleLabel = new KDLabelView
      for      : "sshtitle"
      title    : "Label"

    @titleInput = new KDInputView
      placeholder  : "Label your SSH key here..."
      name         : "sshtitle"
      label        : @titleLabel

    @keyTextLabel = new KDLabelView
      for      : "sshkey"
      title    : "SSH Key"

    @keyTextarea = new KDInputView
      placeholder  : "Paste your SSH key here..."
      type         : "textarea"
      name         : "sshkey"
      cssClass     : "light"
      label        : @keyTextLabel

  viewAppended:->

    @addSubView formline1 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "formline"

    formline1.addSubView @titleLabel
    formline1.addSubView @titleInput
    formline1.addSubView @keyTextLabel
    formline1.addSubView @keyTextarea

    @addSubView formline2 = new KDCustomHTMLView
      cssClass : "button-holder"

    formline2.addSubView save = new KDButtonView
      style        : "cupid-green savebtn"
      title        : "Save"
      callback     : => @emit "FormSaved"

    formline2.addSubView cancel = new KDCustomHTMLView
      tagName      : "button"
      partial      : "Cancel"
      cssClass     : "cancel-link clean-gray button"
      click        : => @emit "FormCancelled"

    formline2.addSubView deletebtn = new KDButtonView
      style        : "clean-red deletebtn"
      title        : "Delete"
      callback     : => @emit "FormDeleted"

    # @addSubView actionsWrapper = new KDCustomHTMLView
    #   tagName : "div"
    #   cssClass : "actions-wrapper"




class AccountSshKeyListItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview clearfix #{cssClass}'></li>"

  viewAppended:->

    super

    @form = form = new AccountSshKeyForm
      delegate : this
      cssClass : "posrelative"

    {title, key} = @getData()

    form.titleInput.setValue  title if title
    form.keyTextarea.setValue key   if key

    @info = info = new KDCustomHTMLView
      tagName  : "span"
      partial  : """<div>
                      <span class="title">#{@getData().title}</span>
                      <span class="key">#{@getData().key.substr(0,45)} . . . #{@getData().key.substr(-25)}</span>
                    </div>"""
      cssClass : "posstatic"

    info.addSubView editLink = new KDCustomHTMLView
      tagName  : "a"
      partial  : "Edit"
      cssClass : "action-link"
      click    : @bound "swapSwappable"

    @swappable = swappable = new AccountsSwappable
      views : [form,info]
      cssClass : "posstatic"

    @addSubView swappable,".swappable-wrapper"

    form.on "FormCancelled", @bound "cancelItem"
    form.on "FormSaved", @bound "saveItem"
    form.on "FormDeleted", @bound "deleteItem"

  swapSwappable:->
    @swappable.swapViews()

  cancelItem:->
    {key} = @getData()
    if key then @swappable.swapViews() else @deleteItem()

  deleteItem:->
    @getDelegate().emit "RemoveItem", @

  saveItem:->
    @setData
      key   : @form.keyTextarea.getValue()
      title : @form.titleInput.getValue()

    {key, title} = @getData()

    if key and title
      @info.$('span.title').text title
      @info.$('span.key').text "#{key.substr(0,45)} . . . #{key.substr(-25)}"
      @swappable.swapViews()
      @getDelegate().emit "UpdatedItems"
    else
      new KDNotificationView
        title : "Key shouldn't be empty."

  partial:(data)->
    """
      <div class='swappableish swappable-wrapper posstatic'></div>
    """







