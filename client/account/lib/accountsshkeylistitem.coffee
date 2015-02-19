kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields
KDListItemView = kd.ListItemView
KDNotificationView = kd.NotificationView
AccountsSwappable = require './accountsswappable'
$ = require 'jquery'
Encoder = require 'htmlencode'


module.exports = class AccountSshKeyListItem extends KDListItemView
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
      cssClass : "ssh-key-item clearfix"
      partial  : """
      <div class='ssh-key-info'>
        <h4><span class="title">#{@getData().title}</span></h4>
        <p><span class="key">#{@getData().key.substr(0,45)} . . . #{@getData().key.substr(-25)}</span></p>
      </div>
      """

    info.addSubView buttons = new KDCustomHTMLView
      cssClass : 'buttons'

    buttons.addSubView editLink = new KDButtonView
      title    : "Edit"
      cssClass : "edit"
      style    : "solid medium green"
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

