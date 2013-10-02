class ActivityDiscussionWidget extends ActivityWidgetFormView

  constructor :(options,data)->

    super options,data

    @preview = options.preview or {}

    @labelTitle = new KDLabelView
      title     : "New Discussion"
      cssClass  : "first-label"

    @labelContent = new KDLabelView
      title : "Content:"

    @inputDiscussionTitle = new KDInputView
      name          : "title"
      label         : @labelTitle
      cssClass      : "warn-on-unsaved-data"
      placeholder   : "Give a title to what you want to start discussing..."
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Discussion title is required!"

    @inputContent = new KDInputViewWithPreview
      label       : @labelContent
      preview     : @preview
      name        : "body"
      cssClass    : "discussion-body warn-on-unsaved-data"
      type        : "textarea"
      autogrow    : yes
      placeholder : "What do you want to talk about? (You can use markdown here)"
      validate    :
        rules     :
          required: yes
        messages  :
          required: "Discussion content is required!"

    @cancelBtn = new KDButtonView
      title    : "Cancel"
      style    : "modal-cancel"
      callback : =>
        @reset()
        @parent.getDelegate().emit "ResetWidgets"

    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Start your discussion"
      type  : 'submit'


    @heartBox = new HelpBox
      subtitle : "About Discussions"
      tooltip  :
        title  : "This is a public wall, here you can discuss anything with the Koding community."

  submit:->
    @once "FormValidationPassed", =>
      KD.track "Activity", "DiscussionSubmitted"
      @reset()
    super
    @submitBtn.disable()
    @utils.wait 8000, => @submitBtn.enable()

  reset:->
    @submitBtn.setTitle "Start your discussion"
    @removeCustomData "activity"
    @inputDiscussionTitle.setValue ''
    @inputContent.setValue ''
    @inputContent.resize()

    # deferred resets
    @utils.defer => @tagController.reset()

    super

  viewAppended:->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  switchToEditView:(activity,fake=no)->

    unless fake
      @submitBtn.setTitle "Edit Discussion"
      @addCustomData "activity", activity
    else
      @submitBtn.setTitle 'Submit again'

    {title, body, tags} = activity

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @inputDiscussionTitle.setValue Encoder.htmlDecode title
      @inputContent.setValue Encoder.htmlDecode body

    fillForm()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder">
        <div class="formline">
          {{> @labelTitle}}
          <div>
            {{> @inputDiscussionTitle}}
          </div>
        </div>
        <div class="formline">
          {{> @labelContent}}
          <div>
            {{> @inputContent}}
          </div>
        </div>
        <div class="formline">
          {{> @labelAddTags}}
          <div>
            {{> @tagAutoComplete}}
            {{> @selectedItemWrapper}}
          </div>
        </div>
        <div class="formline submit">
          <div class='formline-wrapper'>
            <div class="submit-box fr">
              {{> @submitBtn}}
              {{> @cancelBtn}}
            </div>
            {{> @heartBox}}
          </div>
        </div>
      </div>
    </div>
    """