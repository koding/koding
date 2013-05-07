class GroupGeneralSettingsView extends JView

  constructor:->

    super

    @setClass "general-settings-view group-admin-modal"

    group = @getData()

    unless group?
      group = {}
      isNewGroup = yes
    isPrivateGroup = 'private' is group.privacy

    _updateGroupHandler =(group, formData)=>
      group.modify formData, (err)=>
        @settingsForm.buttons.Save.hideLoader()
        if err
          new KDNotificationView
            title: err.message
            duration: 1000
        else
          if formData.privacy isnt group.privacy
            group.privacy = formData.privacy
            if formData.privacy is 'private'
              KD.getSingleton('appManager').tell 'Groups', 'prepareMembershipPolicyTab'
              KD.getSingleton('appManager').tell 'Groups', 'prepareInvitationsTab'
            else
              @parent.parent.removePaneByName 'Membership policy'
              @parent.parent.removePaneByName 'Invitations'

          new KDNotificationView
            title: 'Group was updated!'
            duration: 1000

    formOptions =
      title: if isNewGroup then 'Create a group' else 'Edit group'
      callback:(formData)=>
        if isNewGroup
          _createGroupHandler.call @, formData
        else
          _updateGroupHandler group, formData
      buttons:
        Save                :
          style             : "modal-clean-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
        Cancel              :
          style             : "modal-clean-gray"
          loader            :
            color           : "#ffffff"
            diameter        : 16
          callback          : -> modal.destroy()
      fields:
        Title               :
          label             : "Group Name"
          itemClass         : KDInputView
          name              : "title"
          defaultValue      : Encoder.htmlDecode group.title ? ""
          placeholder       : 'Please enter a title here'
        Description         :
          label             : "Description"
          type              : "textarea"
          itemClass         : KDInputView
          name              : "body"
          defaultValue      : Encoder.htmlDecode group.body ? ""
          placeholder       : 'Please enter a description here.'
          autogrow          : yes
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

    @settingsForm = new KDFormViewWithFields formOptions, @getData()

  viewAppended:->
    super

  pistachio:->
    """
    {{> @settingsForm}}
    """
