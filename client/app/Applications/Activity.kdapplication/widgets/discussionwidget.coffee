class ActivityDiscussionWidget extends KDFormView

  constructor :(options,data)->

    super options,data

    @preview = options.preview or {}

    @labelTitle = new KDLabelView
      title     : "New Discussion"
      cssClass  : "first-label"

    @labelContent = new KDLabelView
      title : "Content:"

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @inputDiscussionTitle = new KDInputView
      name          : "title"
      label         : @labelTitle
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
      cssClass    : "discussion-body"
      type        : "textarea"
      autogrow    : yes
      placeholder : "What do you want to talk about? (You can use markdown here)"
      validate    :
        rules     :
          required: yes
        messages  :
          required: "discussion body is required!"

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
          defaultValue : @inputContent.getValue()

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
                @inputContent.setValue @text.getValue()
                @inputContent.generatePreview()
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

    @selectedItemWrapper = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "tags-selected-item-wrapper clearfix"

    @tagController = new TagAutoCompleteController
      name                : "meta.tags"
      type                : "tags"
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : TagAutoCompletedItemView
      itemDataPath        : 'title'
      outputWrapper       : @selectedItemWrapper
      selectedItemsLimit  : 5
      listWrapperCssClass : "tags"
      form                : @
      dataSource          : (args, callback)=>
        {inputValue} = args
        updateWidget = @getDelegate()
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

  submit:=>
    @once "FormValidationPassed", => @reset()
    super

  reset:=>
    @tagController.reset()
    @submitBtn.setTitle "Start your discussion"
    @removeCustomData "activity"
    @inputDiscussionTitle.setValue ''
    super

  viewAppended:()->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit discussion"
    @addCustomData "activity", activity
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
            <div class="discussion-widget-content">
            {{> @markdownLink}}
            {{> @fullScreenBtn}}
            </div>
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