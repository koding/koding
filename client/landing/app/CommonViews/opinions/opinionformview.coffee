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

    @fullScreenBtn = new KDButtonView
      style           : "clean-gray"
      icon            : yes
      iconClass       : "fullscreen"
      iconOnly        : yes
      cssClass        : "fullscreen-button"
      title           : "Fullscreen Edit"
      callback: =>
        @textContainer = new KDView
          cssClass:"modal-fullscreen-text"

        @text = new KDInputViewWithPreview
          type : "textarea"
          cssClass : "fullscreen-data kdinput text"
          defaultValue : @opinionBody.getValue()

        @textContainer.addSubView @text

        modal = new KDModalView
          title       : "What do you want to discuss?"
          cssClass    : "modal-fullscreen"
          height      : $(window).height()-110
          width       : $(window).width()-110
          view        : @textContainer
          position:
            top       : 55
            left      : 55
          overlay     : yes
          buttons     :
            Cancel    :
              title   : "Discard changes"
              style   : "modal-clean-gray"
              callback:=>
                modal.destroy()
            Apply     :
              title   : "Apply changes"
              style   : "modal-clean-gray"
              callback:=>
                @opinionBody.setValue @text.getValue()
                @opinionBody.generatePreview()
                modal.destroy()

        modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height()-12 # minus the margin, border pixels too..
        modal.$(".fullscreen-data").height modal.$(".kdmodal-content").height()-30-23
        modal.$(".input_preview").height   modal.$(".kdmodal-content").height()-0-21
        modal.$(".input_preview").css maxHeight:  modal.$(".kdmodal-content").height()-0-21
        modal.$(".input_preview div.preview_content").css maxHeight:  modal.$(".kdmodal-content").height()-0-21-10
        contentWidth = modal.$(".kdmodal-content").width()-40
        halfWidth  = contentWidth / 2

        @text.on "PreviewHidden", =>
          modal.$(".fullscreen-data").width contentWidth #-(modal.$("div.preview_switch").width()+20)-10
          modal.$(".input_preview").width (modal.$("div.preview_switch").width()+20)

        @text.on "PreviewShown", =>
          modal.$(".fullscreen-data").width contentWidth-halfWidth-5
          modal.$(".input_preview").width halfWidth-5

        modal.$(".fullscreen-data").width contentWidth-halfWidth-5
        modal.$(".input_preview").width halfWidth-5

    @markdownLink = new KDCustomHTMLView
      tagName     : 'a'
      name        : "markdownLink"
      value       : "markdown is enabled"
      attributes  :
        title     : "markdown is enabled"
        href      : '#'
        value     : "markdown syntax is enabled"
      cssClass    : 'markdown-link'
      partial     : "What is Markdown?<span></span>"
      click       : (event)=>
        if $(event.target).is 'span'
          link.hide()
        else
          markdownText = new KDMarkdownModalText
          modal = new KDModalView
            title       : "How to use the <em>Markdown</em> syntax."
            cssClass    : "what-you-should-know-modal markdown-cheatsheet"
            height      : "auto"
            width       : 500
            content     : markdownText.markdownText()
            buttons     :
              Close     :
                title   : 'Close'
                style   : 'modal-clean-gray'
                callback: -> modal.destroy()

    @heartBox = new HelpBox
      subtitle : "About Discussions"
      tooltip  :
        title  : "Click me for additional information"
      click :->
        modal = new KDModalView
          title          : "Additional information on Discussions"
          content        : "<div class='modalformline signature'><h3>Hi!</h3><p>My name is Arvid, i just recently started to work for Koding and I am responsible for the implementation of Discussions.</p><p>Should you run into bugs, experience strange and/or unexpected behavior or have questions on how to use this feature, please don't hesitate to drop me a mail here: "+@utils.applyTextExpansions("@arvidkahl")+"</p><p>--arvid</p></div>"
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

  viewAppended:()->
    @setClass "update-options opinion"
    @setTemplate @pistachio()
    @template.update()

  submit:=>
    @once "FormValidationPassed", => @reset()
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
            {{> @markdownLink}}
            {{> @fullScreenBtn}}
            {{> @submitOpinionBtn}}
            {{> @cancelOpinionBtn}}
          </div>
        </div>
      </div>
      """