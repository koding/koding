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
      nextElement             :
        showTemplate          :
          itemClass           : KDButtonView
          title               : "Show Template"
          cssClass            : "solid green mini hidden"
          callback            : =>

            { Stack } = @settingsForm.inputs
            data = @_templates["_#{Stack.getValue()}"]
            return new KDNotificationView title: "No data found!"  unless data

            { title, description, rules, domains, machines, extras } = data
            data = { title, description, rules, domains, machines, extras }

            try
              parsed = JSON.stringify data, null, 2
            catch e
              warn e; log data
              return new KDNotificationView
                title: "An error occured"

            new KDModalView
              content : "<pre>#{parsed}</pre>"


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

      else if templates.length is 0

        Stack.setSelectOptions "No template available": []

      else

        @_templates   = {}
        selectOptions = []

        for t in templates
          selectOptions.push { title:t.title, value:t._id }
          @_templates["_#{t._id}"] = t

        selectOptions.push title: "Do not create anything.", value: "none"

        Stack.setSelectOptions "Select stack template..." : selectOptions

        showButton = @settingsForm.inputs["Show Template"]
        showButton.setCss margin: "7px"
        showButton.show()

        if stackTemplates?.length > 0
          Stack.setDefaultValue stackTemplates.first
        else
          Stack.setDefaultValue "none"

  pistachio:-> "{{> @settingsForm}}"
