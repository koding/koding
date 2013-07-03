class AccountSshKeyListController extends KDListViewController
  constructor:(options,data)->
    super options,data

    @loadItems()

    @getListView().on "UpdatedItems", =>
      newKeys = @getItemsOrdered().map (item)-> item.getData()
      KD.remote.api.JUser.setSSHKeys newKeys, ->
        console.log "Saved keys."

    @getListView().on "RemoveItem", (item)=>
      @removeItem item
      @getListView().emit "UpdatedItems"

  loadItems: ()->
    @removeAllItems()
    @showLazyLoader no

    KD.remote.api.JUser.getSSHKeys (keys)=>
      @instantiateListItems keys
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
        @addItem {key: '', title: ''}, 0
        @getListView().items.first.swapSwappable()

class AccountSshKeyList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data

class AccountSshKeyForm extends KDFormView
  viewAppended:->

    @addSubView formline1 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "formline"

    formline1.addSubView @titleInput = new KDInputView
      placeholder  : "Key Name"
      name         : "sshtitle"

    formline1.addSubView @keyTextarea = new KDInputView
      placeholder  : "Paste your SSH key"
      type         : "textarea"
      name         : "sshkey"
      cssClass     : "light"

    {key, title} = @getData()

    @titleInput.setValue  title if title
    @keyTextarea.setValue key   if key

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
    , @getData()

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
    @getData().key = @form.keyTextarea.getValue()
    if @getData().key
      @swappable.swapViews()
    else
      @deleteItem()

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







