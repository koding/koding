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

      @addButton?.destroy()

      @addButton = new KDButtonView
        cssClass  : 'account-add-big-btn'
        title     : 'Add new SSH key'
        icon      : yes
        callback  : =>
          unless @newItem
            @newItem = true
            @addItem {key: '', title: ''}, 0
            @getListView().items.first.swapSwappable hideDelete: yes
            
      @getListView().addSubView @addButton, '', yes 

class AccountSshKeyList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data

class AccountSshKeyListItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview clearfix #{cssClass}'></li>"

  viewAppended:->

    super
    @form = form = new KDFormViewWithFields
      cssClass          : 'add-key-form'
      fields            :
        title           :
          placeholder   : 'Your SSH key title'
          name          : 'sshtitle'
          cssClass      : 'medium'
        key             :
          placeholder   : 'Your SSH key'
          type          : 'textarea'
          name          : 'sshkey'
      buttons           :
        save            :
          style         : 'solid medium green'
          loader        : yes
          title         : 'Save'
          callback      : => @emit 'FormSaved'
        cancel          :
          style         : 'solid medium light-gray'
          title         : 'Cancel'
          callback      : => @emit 'FormCancelled'
        remove          :
          style         : 'solid medium red'
          title         : 'Delete'
          callback      : => @emit 'FormDeleted'

    {title, key} = @getData()

    form.inputs["title"].setValue Encoder.htmlDecode title  if title
    form.inputs["key"].setValue key if key

    @info = info = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "ssh-key-item"
      partial  : """
      <div class="title">#{@getData().title}</div>
      <div class="key">#{@getData().key.substr(0,45)} . . . #{@getData().key.substr(-25)}</div>
      """

    info.addSubView editLink = new KDButtonView
      title    : "Edit"
      cssClass : "edit"
      style    : "solid small green"
      callback : @bound "swapSwappable"

    @swappable = swappable = new AccountsSwappable
      views : [form,info]
      cssClass : "posstatic"

    @addSubView swappable,".swappable-wrapper"

    @on "FormCancelled", @bound "cancelItem"
    @on "FormSaved", @bound "saveItem"
    @on "FormDeleted", @bound "deleteItem"

  swapSwappable: (options)->
    if options.hideDelete
      @form.buttons.remove.hide()
    else
      @form.buttons.remove.show()
    @swappable.swapViews()

  cancelItem:->
    {key} = @getData()
    if key then @swappable.swapViews() else @deleteItem()

  deleteItem:->
    @getDelegate().emit "RemoveItem", @

  saveItem:->
    @form.buttons.save.showLoader()
    @setData
      title : @form.inputs["title"].getValue()
      key   : @form.inputs["key"].getValue()

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
    @form.buttons.save.hideLoader()

  partial:(data)->
    """
      <div class='swappableish swappable-wrapper posstatic'></div>
    """







