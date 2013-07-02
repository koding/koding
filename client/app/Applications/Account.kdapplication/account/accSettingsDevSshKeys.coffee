class AccountSshKeyListController extends KDListViewController
  constructor:(options,data)->
    super options,data

    @loadItems()

    @getListView().controller = @

    @on "UpdatedItems", =>
      newKeys = @getItemsOrdered().map (item)-> item.getData()
      KD.remote.api.JUser.setSSHKeys newKeys, ->
        console.log "Updated keys", arguments

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
        @getListView().addNewKey @

class AccountSshKeyList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data
    console.log @getDelegate()

  addNewKey: (controller)->
    controller.addItem {key: '', title: ''}, 0
    @items.first.swapSwappable()

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

    @titleInput.setValue @data.title if @data.title
    @keyTextarea.setValue @data.key if @data.key

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
      delegate : @
      cssClass : "posrelative"
    ,@data

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
    @data.key = @form.keyTextarea.getValue()
    if @data.key
      @swappable.swapViews()
    else
      @deleteItem()

  deleteItem:->
    {controller} = @getDelegate()
    controller.removeItem @
    controller.emit "UpdatedItems"

  saveItem:->
    {controller} = @getDelegate()
    @data =
      key   : @form.keyTextarea.getValue()
      title : @form.titleInput.getValue()
    if @data.key and @data.title
      @info.$('div.title').text @data.title
      @info.$('div.key').text @data.key
      @swappable.swapViews()
      controller.emit "UpdatedItems"
    else
      new KDNotificationView
        title : "Key shouldn't be empty."

  partial:(data)->
    """
      <div class='swappableish swappable-wrapper posstatic'></div>
    """







