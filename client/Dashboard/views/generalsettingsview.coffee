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
    group              = @getData()
    formOptions.fields = {}

    if group.slug isnt "koding"
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

    formOptions.fields.Stack =
      itemClass               : KDSelectBox
      label                   : "Stack"
      type                    : "select"
      name                    : "stackTemplates"
      selectOptions           : [
        { title: "Loading stack templates...", disabled: yes }
      ]

    formOptions.fields["Visibility settings"] =
      itemClass               : KDSelectBox
      label                   : "Visibility"
      type                    : "select"
      name                    : "visibility"
      defaultValue            : group.visibility ? "visible"
      selectOptions           : [
        { title : "Visible"   , value : "visible" }
        { title : "Hidden"    , value : "hidden"  }
      ]

  createFormButtons: (formOptions) ->
    formOptions.buttons   =
      Save                :
        style             : "solid medium green"
        type              : "submit"
        loader            : yes

  saveSettings: (formData) ->
    saveButton = @settingsForm.buttons.Save
    group      = @getData()

    if formData.stackTemplates is "none"
      formData.stackTemplates = []
    else
      formData.stackTemplates = [ formData.stackTemplates ]

    group.modify formData, (err)->
      saveButton.hideLoader()
      return KD.showError err if err

      new KDNotificationView
        title    : "Group settings saved"
        type     : "mini"
        cssClass : "success"
        duration : 4000

  viewAppended:->
    super

    { stackTemplates } = @getData()
    { Stack } = @settingsForm.inputs

    KD.remote.api.JStackTemplate.some {}, (err, templates)=>

      Stack.removeSelectOptions()

      if err
        Stack.setSelectOptions "Failed to fetch templates": []
        warn err
      else
        templates = ({title:t.title, value:t._id} for t in templates)
        templates.push title: "Do not create anything.", value: "none"

        Stack.setSelectOptions "Select stack template..." : templates

      if stackTemplates?.length > 0
        Stack.setDefaultValue stackTemplates.first
      else
        Stack.setDefaultValue "none"

  pistachio:-> "{{> @settingsForm}}"
