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
      keyup :=>
        if @discussionEmbedLink.getValue() is ""
          @getDelegate().embedBox.resetEmbedAndHide()
      focus:=>
        # @getDelegate().embedBox.show()
      blur:=>
        # @getDelegate().embedBox.hide()
      paste:=>
          @utils.wait =>

            @discussionEmbedLink.setValue @sanitizeUrls @discussionEmbedLink.getValue()

            url = @discussionEmbedLink.getValue()

            if /^((http(s)?\:)?\/\/)/.test url
              # parse this for URL
              @getDelegate().embedBox.embedUrl url,
                maxWidth: 540
                maxHeight: 200
              , =>
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
        KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

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
    # @once "FormValidationPassed", => @reset()
    @removeCustomData "link"

    if @getDelegate().embedBox.hasValidContent
      @addCustomData "link",
        link_cache: @getDelegate().embedBox.getEmbedCache()
        link_url : @getDelegate().embedBox.getEmbedURL()
        link_embed : @getDelegate().embedBox.getEmbedDataForSubmit()
        link_embed_hidden_items:@getDelegate().embedBox.getEmbedHiddenItems()
        link_embed_image_index:@getDelegate().embedBox.getEmbedImageIndex()
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
            {{> @submitDiscussionBtn}}
            {{> @cancelDiscussionBtn}}
          </div>
        </div>
      </div>
      """