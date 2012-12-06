class OpinionFormView extends KDFormView

  constructor :(options, data)->

    # whether or not to show the preview area when the form is
    # initially shown
    @preview = options.preview or {}

    super

    {profile} = KD.whoami()

    @submitOpinionBtn = new KDButtonView
      title           : options.submitButtonTitle or "Post your reply"
      type            : "submit"
      cssClass        : "clean-gray opinion-submit-button"
      loader          :
        diameter      : 12

    @cancelOpinionBtn = new KDButtonView
      title : "Cancel"
      cssClass:"modal-cancel opinion-cancel"
      type : "button"
      style: "modal-cancel"
      callback :=>
        @parent?.editLink.$().click()

    @showMarkdownPreview = options.previewVisible

    @opinionBody = new KDInputViewWithPreview
      preview         : @preview
      cssClass        : "opinion-body"
      name            : "body"
      title           : "your Opinion"
      type            : "textarea"
      placeholder     : "What do you want to contribute to the discussion?"

    @labelAddTags = new KDLabelView
      title           : "Add Tags:"

    @selectedItemWrapper = new KDCustomHTMLView
      tagName         : "div"
      cssClass        : "tags-selected-item-wrapper clearfix"

    @heartBox = new HelpBox
      subtitle : "About Answers and Opinions"
      tooltip  :
        title  : "Click me for additional information"
      click :->
        modal = new KDModalView
          title          : "Additional information on Discussions"
          content        : "<div class='modalformline signature'><p>Here you can edit your replies.</p></div>"
          height         : "auto"
          overlay        : yes
          buttons        :
            Okay       :
              style      : "modal-clean-gray"
              loader     :
                color    : "#ffffff"
                diameter : 16
              callback   : =>
                modal.buttons.Okay.hideLoader()
                modal.destroy()

    if data instanceof KD.remote.api.JOpinion
      @opinionBody.setValue Encoder.htmlDecode data.body
      @opinionBody.generatePreview()

  viewAppended:()->
    @setClass "update-options opinion"
    @setTemplate @pistachio()
    @template.update()

  reset:=>
    @opinionBody.setValue ""
    super

  submit:=>
    # @once "FormValidationPassed", => @reset()
    super

  pistachio:->
      """
      <div class="opinion-box" id="opinion-form-box">
        <div class="opinion-form">
          {{> @opinionBody}}
        </div>
        <div class="opinion-buttons">
          <div class="opinion-heart-box">
            {{> @heartBox}}
          </div>
          <div class="opinion-submit">
            {{> @submitOpinionBtn}}
            {{> @cancelOpinionBtn}}
          </div>
        </div>
      </div>
      """