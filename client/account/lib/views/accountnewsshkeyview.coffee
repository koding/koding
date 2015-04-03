kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields
KDButtonBar = kd.ButtonBar
KDListItemView = kd.ListItemView
KDListViewController = kd.ListViewController
KDNotificationView = kd.NotificationView
AccountSshMachineList = require './accountsshmachinelist'
$ = require 'jquery'
Encoder = require 'htmlencode'
showError = require 'app/util/showError'


module.exports = class AccountNewSshKeyView extends KDListItemView

  @ViewType = {
  	'NoMachines'
  	'SingleMachine'
  	'ManyMachines'
  }

  setDomElement: (cssClass) ->

    @domElement = $ "<li class='kdview clearfix #{cssClass}'></li>"


  viewAppended:->

    super

    { type }     = @getOptions()
    { ViewType } = AccountNewSshKeyView

    formWrapper = new KDCustomHTMLView
      cssClass : 'AppModal-form add-ssh-key-view'

    if (type is ViewType.NoMachines)

      noMachinesText = new KDCustomHTMLView
        cssClass : 'formline no-machines-text'
        partial  : 'None of your VM(s) are active. Please turn on a VM before attempting to enter a SSH key.'
      formWrapper.addSubView noMachinesText

      formButtons = new KDButtonBar
        buttons           :
          cancel          :
            style         : 'thin small gray'
            title         : 'Cancel'
            callback      : @lazyBound 'emit', 'FormCancelled'
      formWrapper.addSubView formButtons

    else

      @form = form = new KDFormViewWithFields
        fields            :
          title           :
            cssClass      : 'Formline--half'
            placeholder   : 'Your SSH key title'
            name          : 'sshtitle'
            label         : 'Title'
          key             :
            placeholder   : 'Your SSH key'
            type          : 'textarea'
            name          : 'sshkey'
            label         : 'Key'

      formWrapper.addSubView form

      if type is ViewType.ManyMachines

        @machineList = list = new AccountSshMachineList()
        listController = new KDListViewController view : list
        listController.instantiateListItems @getData().machines
        formWrapper.addSubView list

      @buttonsBar = formButtons = new KDButtonBar
        buttons           :
          save            :
            style         : 'solid small green'
            loader        : yes
            title         : 'Save'
            callback      : @lazyBound 'emit', 'FormSaved'
          cancel          :
            style         : 'thin small gray'
            title         : 'Cancel'
            callback      : @lazyBound 'emit', 'FormCancelled'

      formWrapper.addSubView formButtons

    @addSubView formWrapper

    @on "FormCancelled", @bound "cancel"
    @on "FormSaved", @bound "save"
    @on "KeyFailed", @bound "errorHandled"


  cancel: ->

    @getDelegate().emit "RemoveItem", @


  save: ->

    { type } = @getOptions()
    { ViewType } = AccountNewSshKeyView

    key = @form.inputs["key"].getValue()
    title = @form.inputs["title"].getValue()

    @buttonsBar.buttons.save.showLoader()

    unless key
      showError "Key shouldn't be empty."
    else unless title
      showError "Title required for SSH key."
    else
      machines = switch type
        when ViewType.SingleMachine then @getData().machines
        when ViewType.ManyMachines  then @machineList.getSelectedMachines()
        else []

      unless machines.length > 0
        showError "VM(s) should be selected for SSH key"
      else
        @setData { title, key, machines }
        @getDelegate().emit "NewKeySubmitted", this

    @buttonsBar.buttons.save.hideLoader()


  partial:(data)->
    """
      <div class='swappableish swappable-wrapper posstatic'></div>
    """


  errorHandled: (err) ->

    isInvalidKey = err.message?.indexOf('invalid authorized_key') > -1
    return showError 'Sorry, the SSH key is not in a valid format.'  if isInvalidKey

    showError err.message