class GroupGeneralSettingsView extends JView

  constructor:(options = {}, data)->
    super options,data
    @setClass "general-settings-view group-admin-modal"
    group = @getData()
    delegate = @getDelegate()

    formOptions =
      callback:(formData)=>
        saveButton = @settingsForm.buttons.Save
        appManager = KD.getSingleton('appManager')

        # fix me:  make this a single call
        group.modify formData, (err)=>
          if err
            saveButton.hideLoader()
            return new KDNotificationView { title: err.message, duration: 1000 }

          new KDNotificationView
            title: 'Group was updated!'
            duration: 1000

          delegate.emit "groupSettingsUpdated", group

      buttons:
        Save                :
          style             : "solid green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
        # Remove              :
        #   cssClass   : "modal-clean-red fr"
        #   title      : "Remove this Group"
        #   callback   : =>
        #     modal = new GroupsDangerModalView
        #       action     : 'Remove Group'
        #       title      : "Remove '#{data.slug}'"
        #       longAction : "remove the '#{data.slug}' group"
        #       callback   : (callback)=>
        #         data.remove (err)=>
        #           callback()
        #           return KD.showError err  if err
        #           new KDNotificationView title:'Successfully removed!'
        #           modal.destroy()
        #           location.replace('/')
        #     , data
      fields:
        Title               :
          label             : "Group Name"
          name              : "title"
          defaultValue      : Encoder.htmlDecode group.title ? ""
          placeholder       : 'Please enter a title here'
        Description         :
          label             : "Description"
          type              : "textarea"
          name              : "body"
          defaultValue      : Encoder.htmlDecode group.body ? ""
          placeholder       : 'Please enter a description here.'
          autogrow          : yes
        "Visibility settings"  :
          itemClass         : KDSelectBox
          label             : "Visibility"
          type              : "select"
          name              : "visibility"
          defaultValue      : group.visibility ? "visible"
          selectOptions     : [
            { title : "Visible",    value : "visible" }
            { title : "Hidden",     value : "hidden" }
          ]

    if group.slug isnt "koding"
      formOptions.fields["Logo"] =
        label       : "Logo"
        itemClass   : GroupLogoSettings

    @settingsForm = new KDFormViewWithFields formOptions, group

    # unless KD.config.roles? and 'owner' in KD.config.roles
    #   @settingsForm.buttons.Remove.hide()

    # if data.slug is 'koding'
    #   @settingsForm.buttons.Remove.hide()

  pistachio:-> "{{> @settingsForm}}"
