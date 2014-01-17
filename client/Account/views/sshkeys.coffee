class AccountSshKeyListController extends AccountListViewController
  constructor:(options,data)->

    options.noItemFoundText = "You have no SSH key."
    super options,data

    @loadItems()

    @getListView().on "UpdatedItems", =>
      @newItem = no
      newKeys = @getItemsOrdered().map (item)-> item.getData()
      unless newKeys.length is 0 then @customItem?.destroy()
      KD.remote.api.JUser.setSSHKeys newKeys, -> log "Saved keys."

    @getListView().on "RemoveItem", (item)=>
      @newItem = no
      @removeItem item
      @getListView().emit "UpdatedItems"

    @newItem = no

  loadItems: ()->
    @removeAllItems()
    @showLazyLoader no

    KD.remote.api.JUser.getSSHKeys (keys)=>
      @instantiateListItems keys
      @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "solid green small account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : =>
        unless @newItem
          @newItem = true
          @addItem {key: '', title: ''}, 0
          @getListView().items.first.swapSwappable hideDelete: yes

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

    @titleInput = new KDInputView
      placeholder  : "your SSH key title"
      name         : "sshtitle"
      label        : @titleLabel

    @keyTextarea = new KDInputView
      placeholder  : "your SSH key"
      type         : "textarea"
      name         : "sshkey"
      cssClass     : "light"
      label        : @keyTextLabel

  viewAppended:->

    @addSubView formline1 = new KDCustomHTMLView
      cssClass  : "formline"

    formline1.addSubView @titleInput
    formline1.addSubView @keyTextarea

    @addSubView formline2 = new KDCustomHTMLView
      cssClass : "button-holder"

    formline2.addSubView save = new KDButtonView
      style        : "solid green"
      title        : "Save"
      callback     : => @emit "FormSaved"

    formline2.addSubView cancel = new KDButtonView
      title      : "Cancel"
      cssClass   : "solid"
      callback   : => @emit "FormCancelled"

    formline2.addSubView @deletebtn = new KDButtonView
      style        : "solid red fr"
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

    form.titleInput.setValue Encoder.htmlDecode title  if title
    form.keyTextarea.setValue key  if key

    @info = info = new KDCustomHTMLView
      tagName  : "div"
      partial  : """
      <div class="title">#{@getData().title}<div>
      <div class="key">#{@getData().key.substr(0,45)} . . . #{@getData().key.substr(-25)}</div>
      """
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

  swapSwappable: (options)->
    if options.hideDelete
      @form.deletebtn.hide()
    else
      @form.deletebtn.show()
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
    else unless key
      new KDNotificationView
        title : "Key shouldn't be empty."
    else unless title
      new KDNotificationView
        title : "Title required for SSH key."

  partial:(data)->
    """
      <div class='swappableish swappable-wrapper posstatic'></div>
    """







