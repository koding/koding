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
    controller.addItem '', 0
    @items.first.swapSwappable()

class AccountSshKeyForm extends KDFormView
  viewAppended:->

    @addSubView formline1 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "formline"

    formline1.addSubView @keyTextarea = new KDInputView
      placeholder  : "Paste your SSH key"
      type         : "textarea"
      name         : "sshkey"

    @keyTextarea.setValue @data if @data

    @addSubView formline2 = new KDCustomHTMLView
      cssClass : "button-holder"

    formline2.addSubView save = new KDButtonView
      style        : "clean-gray savebtn"
      title        : "Save"
      callback     : => @emit "FormSaved"

    formline2.addSubView deletebtn = new KDButtonView
      style        : "clean-red deletebtn"
      title        : "Delete"
      callback     : => @emit "FormDeleted"

    @addSubView actionsWrapper = new KDCustomHTMLView
      tagName : "div"
      cssClass : "actions-wrapper"

    actionsWrapper.addSubView cancel = new KDCustomHTMLView
      tagName  : "a"
      partial  : "cancel"
      cssClass : "cancel-link"
      click    : => @emit "FormCancelled"


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
      partial  : "<div class='darkText'>#{@getData()}</div>"
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
    @data = @form.keyTextarea.getValue()
    if @data
      @swappable.swapViews()
    else
      @deleteItem()      

  deleteItem:->
    {controller} = @getDelegate()
    controller.removeItem @
    controller.emit "UpdatedItems"

  saveItem:->
    {controller} = @getDelegate()
    @data = @form.keyTextarea.getValue()
    if @data
      @info.$('div.darkText').text @data
      @swappable.swapViews()
      controller.emit "UpdatedItems"
    else
      new KDNotificationView
        title : "Key shouldn't be empty."

  partial:(data)->
    """
      <div class='labelish'>
        <span class="icon"></span>
        <span class='editor-method-title'></span>
      </div>
      <div class='swappableish swappable-wrapper posstatic'></div>
    """







