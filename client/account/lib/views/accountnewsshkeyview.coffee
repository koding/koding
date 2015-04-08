kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDLabelView = kd.LabelView
KDInputView = kd.InputView
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


  viewAppended: ->

    super

    { type }     = @getOptions()
    { ViewType } = AccountNewSshKeyView

    formWrapper = new KDCustomHTMLView
      cssClass : 'AppModal-form add-ssh-key-view'

    if type is ViewType.NoMachines
      @decorateNoMachineState formWrapper
    else
      @decorateHasMachineState formWrapper, type is ViewType.ManyMachines

    @addSubView formWrapper

    @on "FormCancelled", @bound "cancel"
    @on "FormSaved", @bound "save"
    @on "SubmitFailed", @bound "errorHandled"

    @getDelegate().emit "EditItem", this


  decorateNoMachineState: (formWrapper) ->

    formWrapper.addSubView new KDCustomHTMLView
      cssClass : 'formline no-machines-text'
      partial  : 'None of your VM(s) are active. Please turn on a VM before attempting to enter a SSH key.'

    formWrapper.addSubView new KDButtonBar
      buttons           :
        cancel          :
          style         : 'thin small gray'
          title         : 'Cancel'
          callback      : @lazyBound 'emit', 'FormCancelled'


  addInputView: (options, formWrapper) ->

    wrapper = new KDCustomHTMLView
      cssClass : "formline #{options.cssClass}"

    wrapper.addSubView label = new KDLabelView
      title : options.label
    options.label = label
    wrapper.addSubView input = new KDInputView options

    formWrapper.addSubView wrapper

    return input


  decorateHasMachineState: (formWrapper, manyMachines) ->

    @titleInput = @addInputView {
      cssClass      : 'Formline--half'
      placeholder   : 'Your SSH key title'
      name          : 'sshtitle'
      label         : 'Title'
    }
    , formWrapper

    if manyMachines
      @machineList = list = new AccountSshMachineList()
      listController = new KDListViewController view : list
      listController.instantiateListItems @getData().machines
      list.addFooter()
      formWrapper.addSubView list

    @keyInput = @addInputView {
      placeholder   : 'Your SSH key'
      type          : 'textarea'
      name          : 'sshkey'
      label         : 'Key'
    }
    , formWrapper

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


  cancel: ->

    @getDelegate().emit "RemoveItem", this


  save: ->

    { type } = @getOptions()
    { ViewType } = AccountNewSshKeyView

    key = @keyInput.getValue()
    title = @titleInput.getValue()

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
        @getDelegate().emit "NewItemSubmitted", this

    @buttonsBar.buttons.save.hideLoader()


  partial: -> '<div class="swappableish swappable-wrapper posstatic"></div>'


  errorHandled: (err) ->

    isInvalidKey = err.message?.indexOf('invalid authorized_key') > -1
    return showError 'Sorry, the SSH key is not in a valid format.'  if isInvalidKey

    showError err