class GroupGeneralSettingsView extends JView

  constructor:->

    super

    @setClass "general-settings-view group-admin-modal"

    group = @getData()

    unless group?
      group = {}
      isNewGroup = yes
    isPrivateGroup = 'private' is group.privacy

    _updateGroupHandler =(group, formData)->
      group.modify formData, (err)->
        if err
          new KDNotificationView
            title: err.message
            duration: 1000
        else
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
          style             : "modal-clean-gray"
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
        "Drop Image here"              :
          label             : "Avatar"
          itemClass         : KDImageUploadSingleView
          name              : "avatar"
          limit             : 1
          preview           : 'thumbs'
          actions         : {
            big    :
              [
                'scale', {
                  shortest: 400
                }
                'crop', {
                  width   : 400
                  height  : 400
                }
              ]
            medium         :
              [
                'scale', {
                  shortest: 200
                }
                'crop', {
                  width   : 200
                  height  : 200
                }
              ]
            small         :
              [
                'scale', {
                  shortest: 60
                }
                'crop', {
                  width   : 60
                  height  : 60
                }
              ]
          }
        Title               :
          label             : "Title"
          itemClass         : KDInputView
          name              : "title"
          keydown           : (pubInst, event)=>
            setTimeout =>
              slug = @utils.slugify @settingsForm.inputs.Title.getValue()
              @settingsForm.inputs.Slug.setValue slug
            , 1
          defaultValue      : Encoder.htmlDecode group.title ? ""
          placeholder       : 'Please enter a title here'
        SlugText                :
          itemClass : KDView
          cssClass : 'slug-url'
          partial : '<span class="base">http://www.koding.com/</span>'
          nextElementFlat :
            Slug :
              label             : "Slug"
              itemClass         : KDInputView
              name              : "slug"
              # cssClass          : 'hidden'
              defaultValue      : group.slug ? ""
              placeholder       : 'This value will be automatically generated'
              # disabled          : yes
        Description         :
          label             : "Description"
          type              : "textarea"
          itemClass         : KDInputView
          name              : "body"
          defaultValue      : Encoder.htmlDecode group.body ? ""
          placeholder       : 'Please enter a description here.'
        "Privacy settings"  :
          itemClass         : KDSelectBox
          label             : "Privacy settings"
          type              : "select"
          name              : "privacy"
          defaultValue      : group.privacy ? "public"
          selectOptions     : [
            { title : "Public",    value : "public" }
            { title : "Private",   value : "private" }
          ]
        "Visibility settings"  :
          itemClass         : KDSelectBox
          label             : "Visibility settings"
          type              : "select"
          name              : "visibility"
          defaultValue      : group.visibility ? "visible"
          selectOptions     : [
            { title : "Visible",    value : "visible" }
            { title : "Hidden",     value : "hidden" }
          ]

    @settingsForm = new KDFormViewWithFields formOptions, @getData()


    avatarUploadView = @settingsForm.inputs["Drop Image here"]
    avatarUploadView.on 'FileReadComplete', (stuff)->
      avatarUploadView.$('.kdfileuploadarea').css
        backgroundImage : "url(#{stuff.file.data})"
      avatarUploadView.$('span').addClass 'hidden'
   
  viewAppended:->
    super

  pistachio:->
    """
    {{> @settingsForm}}
    """
