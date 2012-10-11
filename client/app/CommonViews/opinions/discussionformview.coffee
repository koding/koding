class DiscussionFormView extends KDFormView

  constructor :(options, data)->

    super

    {profile} = KD.whoami()

    @submitDiscussionBtn = new KDButtonView
      title           : "Save your changes"
      type            : "submit"
      cssClass        : "clean-gray discussion-submit-button"
      loader          :
        diameter      : 12

    @discussionBody = new KDInputView
      cssClass        : "discussion-body"
      name            : "body"
      title           : "your Discussion Topic"
      type            : "textarea"
      # autogrow        : yes
      placeholder     : "What do you want to contribute to the discussion?"

    @discussionTitle = new KDInputView
      cssClass        : "discussion-title"
      name            : "title"
      title           : "your Opinion"
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
      callback: =>
        modal = new KDModalView
          title       : "What do you want to discuss?"
          cssClass    : "modal-fullscreen"
          height      : $(window).height()-110
          width       : $(window).width()-110
          position:
            top       : 55
            left      : 55
          overlay     : yes
          content     : "<div class='modal-fullscreen-text'><textarea class='kdinput text' id='fullscreen-data'>"+@discussionBody.getValue()+"</textarea></div>"
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
                @discussionBody.setValue $("#fullscreen-data").val()
                modal.destroy()

        modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height()-12 # minus the margin, border pixels too..
        modal.$("#fullscreen-data").height modal.$(".kdmodal-content").height()-30
        modal.$("#fullscreen-data").width modal.$(".kdmodal-content").width()-40

    @markdownLink = new KDCustomHTMLView
      tagName     : 'a'
      name        : "markdownLink"
      value       : "markdown is enabled"
      attributes  :
        title     : "markdown is enabled"
        href      : '#'
        value     : "markdown syntax is enabled"
      cssClass    : 'markdown-link'
      partial     : "markdown is enabled<span></span>"
      click       : (pubInst, event)=>
        if $(event.target).is 'span'
          link.hide()
        else
          markdownText = new KDMarkdownModalText
          modal = new KDModalView
            title       : "How to use the <em>markdown</em> syntax."
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

    if data instanceof KD.remote.api.JDiscussion
      @discussionBody.setValue Encoder.htmlDecode data.body
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

  viewAppended:()->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  submit:=>
    @once "FormValidationPassed", => @reset()
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
            {{> @markdownLink}}
            {{> @fullScreenBtn}}
            {{> @submitDiscussionBtn}}
          </div>
        </div>
      </div>
      """