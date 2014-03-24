class GroupsMembershipPolicyLanguageEditor extends JView

  constructor:->
    super
    @setClass 'policylanguage-editor'
    policy = @getData()

    @editorLabel = new KDLabelView
      title : 'Custom Policy Language'

    @editor = new KDInputView
      label           : @editorLabel
      type            : 'textarea'
      defaultValue    : policy.explanation
      keydown         : => @saveButton.enable()
      preview         :
        showInitially : no

    @cancelButton = new KDButtonView
      title     : "Cancel"
      cssClass  : "clean-gray"
      callback  : =>
        @hide()
        @emit 'EditorClosed'

    @saveButton = new KDButtonView
      title     : "Save"
      cssClass  : "cupid-green"
      callback  : =>
        @saveButton.disable()
        @emit 'PolicyLanguageChanged', explanation: @editor.getValue()

  pistachio:->
    """
    {{> @editorLabel}}{{> @editor}}{{> @saveButton}}{{> @cancelButton}}
    """
