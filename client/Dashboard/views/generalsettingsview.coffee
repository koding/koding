class GroupGeneralSettingsView extends JView

  constructor: (options = {}, data) ->

    super options,data

    @setClass "general-settings-view group-admin-modal"

    formOptions = {}
    formOptions.callback = (formData) =>
      @saveSettings formData

    @createFormButtons formOptions
    @createFormFields  formOptions

    @settingsForm = new KDFormViewWithFields formOptions, @getData()

    # unless KD.config.roles? and 'owner' in KD.config.roles
    #   @settingsForm.buttons.Remove.hide()

    # if data.slug is 'koding'
    #   @settingsForm.buttons.Remove.hide()

  createFormFields: (formOptions) ->
    group = @getData()

    if group.slug isnt "koding"
      formOptions.fields      = {}
      formOptions.fields.Logo =
        label                 : "Logo"
        itemClass             : GroupLogoSettings

    formOptions.fields.Title  =
      label                   : "Group Name"
      name                    : "title"
      defaultValue            : Encoder.htmlDecode group.title ? ""
      placeholder             : 'Please enter a title here'

    formOptions.fields.Description =
      label                   : "Description"
      type                    : "textarea"
      name                    : "body"
      defaultValue            : Encoder.htmlDecode group.body ? ""
      placeholder             : 'Please enter a description here.'
      autogrow                : yes

    formOptions.fields["Visibility settings"] =
      itemClass               : KDSelectBox
      label                   : "Visibility"
      type                    : "select"
      name                    : "visibility"
      defaultValue            : group.visibility ? "visible"
      selectOptions           : [
        { title : "Visible"   ,    value : "visible" }
        { title : "Hidden"    ,     value : "hidden" }
      ]

  createFormButtons: (formOptions) ->
    formOptions.buttons   =
      Save                :
        style             : "solid green"
        type              : "submit"
        loader            :
          color           : "#444444"
          diameter        : 12

  saveSettings: (formData) ->
    saveButton = @settingsForm.buttons.Save
    appManager = KD.getSingleton "appManager"
    delegate   = @getDelegate()
    group      = @getData()

    # fix me:  make this a single call
    group.modify formData, (err)=>
      if err
        saveButton.hideLoader()
        return new KDNotificationView { title: err.message, duration: 1000 }

      new KDNotificationView
        title    : "Group settings saved"
        type     : "mini"
        cssClass : "success"
        duration : 4000

      delegate.emit "groupSettingsUpdated", group

  pistachio:-> "{{> @settingsForm}}"
