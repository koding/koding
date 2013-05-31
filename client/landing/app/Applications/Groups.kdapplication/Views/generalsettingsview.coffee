class GroupGeneralSettingsView extends JView

  constructor:->
    super
    @setClass "general-settings-view group-admin-modal"
    group = @getData()

    formOptions =
      callback:(formData)=>
        {readme}   = formData
        saveButton = @settingsForm.buttons.Save
        appManager = KD.getSingleton('appManager')
        delete formData.readme
        # fix me:  make this a single call
        group.modify formData, (err)=>
          if err
            saveButton.hideLoader()
            return new KDNotificationView { title: err.message, duration: 1000 }
          group.setReadme readme, (err)=>
            saveButton.hideLoader()
            return new KDNotificationView { title: err.message, duration: 1000 }  if err
            if formData.privacy isnt group.privacy
              group.privacy = formData.privacy
              for navTitle in ['Membership policy', 'Invitations']
                navController = @parent.parent.parent.navController
                if formData.privacy is 'private'
                  navController.getItemByName(navTitle).unsetClass 'hidden'
                else
                  navController.getItemByName(navTitle).setClass 'hidden'

            new KDNotificationView
              title: 'Group was updated!'
              duration: 1000

      buttons:
        Save                :
          style             : "modal-clean-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
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
        Readme              :
          label             : "Readme"
          name              : "readme"
          itemClass         : GroupReadmeView
          defaultValue      : Encoder.htmlDecode group.readme ? ""
          data              : group
        "Privacy settings"  :
          itemClass         : KDSelectBox
          label             : "Privacy"
          type              : "select"
          name              : "privacy"
          defaultValue      : group.privacy ? "public"
          selectOptions     : [
            { title : "Public",    value : "public" }
            { title : "Private",   value : "private" }
          ]
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

    @settingsForm = new KDFormViewWithFields formOptions, group

  pistachio:-> "{{> @settingsForm}}"
