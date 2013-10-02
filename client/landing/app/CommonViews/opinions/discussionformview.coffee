class DiscussionFormView extends KDFormView

  constructor :(options, data)->

    super

    @preview = options.preview or {}

    {profile} = KD.whoami()

    @submitDiscussionBtn = new KDButtonView
      title           : "Save your changes"
      type            : "submit"
      cssClass        : "clean-gray discussion-submit-button"
      loader          :
        diameter      : 12

    @cancelDiscussionBtn = new KDButtonView
      title : "Cancel"
      cssClass:"modal-cancel discussion-cancel"
      type : "button"
      style: "modal-cancel"
      callback :=>
        @parent?.editDiscussionLink.$().click()

    @discussionBody = new KDInputViewWithPreview
      preview         : @preview
      cssClass        : "discussion-body"
      name            : "body"
      title           : "your Discussion Topic"
      type            : "textarea"
      placeholder     : "What do you want to contribute to the discussion?"

    @discussionTitle = new KDInputView
      cssClass        : "discussion-title"
      name            : "title"
      title           : "your Opinion"
      type            : "text"
      placeholder     : "What do you want to talk about?"

    if data instanceof KD.remote.api.JDiscussion
      @discussionBody.setValue Encoder.htmlDecode data.body
      @discussionTitle.setValue Encoder.htmlDecode data.title

    # @on "discussion.changeMarkdown", (value) ->
      # once markdown usage can be switched on and off, this will be used

  viewAppended:->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  submit:->
    # @once "FormValidationPassed", => @reset()
    super

  pistachio:->
      """
      <div class="discussion-box">
        <div class="discussion-form">
          {{> @discussionTitle}}
          {{> @discussionBody}}
        </div>
        <div class="discussion-buttons">
          <div class="discussion-submit">
            {{> @submitDiscussionBtn}}
            {{> @cancelDiscussionBtn}}
          </div>
        </div>
      </div>
      """