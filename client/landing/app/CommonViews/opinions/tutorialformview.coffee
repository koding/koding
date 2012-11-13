class TutorialFormView extends KDFormView

  constructor :(options, data)->

    super

    @preview = options.preview or {}

    {profile} = KD.whoami()

    @submitDiscussionBtn = new KDButtonView
      title           : "Save your changes"
      type            : "submit"
      cssClass        : "clean-gray tutorial-submit-button"
      loader          :
        diameter      : 12

    @cancelDiscussionBtn = new KDButtonView
      title : "Cancel"
      cssClass:"modal-cancel tutorial-cancel"
      type : "button"
      style: "modal-cancel"
      callback :=>
        @parent?.editDiscussionLink.$().click()

    @discussionBody = new KDInputViewWithPreview
      preview         : @preview
      cssClass        : "tutorial-body"
      name            : "body"
      title           : "your Tutorial"
      type            : "textarea"
      placeholder     : "What do you want to contribute to the tutorial?"

    @discussionEmbedLink = new KDInputView
      cssClass        : "tutorial-title"
      name            : "embed"
      title           : "your Video"
      type            : "text"
      placeholder     : "The URL to your video"
      focus:=>
        @getDelegate().embedBox.show()
      blur:=>
        @getDelegate().embedBox.hide()
      paste:=>
          @utils.wait =>

            @discussionEmbedLink.setValue @sanitizeUrls @discussionEmbedLink.getValue()

            url = @discussionEmbedLink.getValue()

            if /^((http(s)?\:)?\/\/)/.test url
              # parse this for URL
              @getDelegate().embedBox.embedUrl url, {
                maxWidth: 540
                maxHeight: 200
              }, =>
                @getDelegate().embedBox.show()

    @discussionTitle = new KDInputView
      cssClass        : "tutorial-title"
      name            : "title"
      title           : "your Tutorial title"
      type            : "text"
      placeholder     : "What do you want to talk about?"

    @labelAddTags = new KDLabelView
      title           : "Add Tags:"

    @selectedItemWrapper = new KDCustomHTMLView
      tagName         : "div"
      cssClass        : "tags-selected-item-wrapper clearfix"

    @fullScreenBtn = new KDButtonView
      style           : "clean-gray"
      cssClass        : "fullscreen-button"
      title           : "Fullscreen Edit"
      icon            : yes
      iconClass       : "fullscreen"
      iconOnly        : yes
      callback: =>
        @textContainer = new KDView
          cssClass:"modal-fullscreen-text"

        @text = new KDInputViewWithPreview
          type : "textarea"
          cssClass : "fullscreen-data kdinput text"
          defaultValue : @discussionBody.getValue()

        @textContainer.addSubView @text


        modal = new KDModalView
          title       : "Please enter your Tutorial content."
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
                @discussionBody.setValue @text.getValue()
                @discussionBody.generatePreview()
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

        # modal = new KDModalView
        #   title       : "What do you want to discuss?"
        #   cssClass    : "modal-fullscreen"

        #   height      : $(window).height()-110
        #   width       : $(window).width()-110
        #   position:
        #     top       : 55
        #     left      : 55
        #   overlay     : yes
        #   content     : "<div class='modal-fullscreen-text'><textarea class='kdinput text' id='fullscreen-data'>"+@discussionBody.getValue()+"</textarea></div>"
        #   buttons     :
        #     Cancel    :
        #       title   : "Discard changes"
        #       style   : "modal-clean-gray"
        #       callback:=>
        #         modal.destroy()
        #     Apply     :
        #       title   : "Apply changes"
        #       style   : "modal-clean-gray"
        #       callback:=>
        #         @discussionBody.setValue $("#fullscreen-data").val()
        #         @discussionBody.generatePreview()
        #         modal.destroy()

        # modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height()-12 # minus the margin, border pixels too..
        # modal.$("#fullscreen-data").height modal.$(".kdmodal-content").height()-30
        # modal.$("#fullscreen-data").width modal.$(".kdmodal-content").width()-40

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

    @markdownSelect = new KDSelectBox
      type          : "select"
      name          : "markdown"
      cssClass      : "select markdown-select hidden"
      selectOptions :
          [
              title : "enable markdown syntax"
              value : "markdown"
            ,
              title : "disable markdown syntax"
              value : "nomarkdown"
          ]
      defaultValue  : "markdown"
      callback      : (value) =>
        @emit "opinion.changeMarkdown", value

    if data instanceof KD.remote.api.JTutorial
      @discussionBody.setValue Encoder.htmlDecode data.body
      @discussionEmbedLink.setValue Encoder.htmlDecode data.link?.link_url
      @discussionTitle.setValue Encoder.htmlDecode data.title

    @on "discussion.changeMarkdown", (value) ->
      # once markdown usage can be switched on and off, this will be used

    @tagController = new TagAutoCompleteController
      name                : "meta.tags"
      type                : "tags"
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : TagAutoCompletedItemView
      outputWrapper       : @selectedItemWrapper
      selectedItemsLimit  : 5
      listWrapperCssClass : "tags"
      itemDataPath        : 'title'
      form                : @
      dataSource          : (args, callback)=>
        {inputValue} = args
        updateWidget = @getDelegate()
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

  sanitizeUrls:(text)->
    text.replace /(([a-zA-Z]+\:)\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g, (url)=>
      test = /^([a-zA-Z]+\:\/\/)/.test url

      if test is no

        # here is a warning/popup that explains how and why
        # we change the links in the edit

        "http://"+url

      else

        # if a protocol of any sort is found, no change

        url

  viewAppended:()->
    @setClass "update-options tutorial"
    @setTemplate @pistachio()
    @template.update()

  submit:=>
    @once "FormValidationPassed", => @reset()

    if @getDelegate().embedBox.hasValidContent
      @addCustomData "link", {
        link_cache: @getDelegate().embedBox.getEmbedCache()
        link_url : @getDelegate().embedBox.getEmbedURL()
        link_embed : @getDelegate().embedBox.getEmbedDataForSubmit()
        link_embed_hidden_items:@getDelegate().embedBox.getEmbedHiddenItems()
        link_embed_image_index:@getDelegate().embedBox.getEmbedImageIndex()
      }

    super

  pistachio:->
      """
      <div class="tutorial-box">
        <div class="tutorial-form">
          {{> @discussionTitle}}
          {{> @discussionEmbedLink}}
          {{> @discussionBody}}
        </div>
        <div class="tutorial-buttons">
          <div class="tutorial-submit">
            {{> @markdownLink}}
            {{> @fullScreenBtn}}
            {{> @submitDiscussionBtn}}
            {{> @cancelDiscussionBtn}}
          </div>
        </div>
      </div>
      """