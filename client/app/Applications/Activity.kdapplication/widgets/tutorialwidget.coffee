class ActivityTutorialWidget extends KDFormView

  constructor :(options,data)->

    super options,data

    @preview = options.preview or {}

    @labelTitle = new KDLabelView
      title     : "New Tutorial"
      cssClass  : "first-label"

    @labelEmbedLink = new KDLabelView
      title : "Video URL:"

    @labelContent = new KDLabelView
      title : "Content:"

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @inputDiscussionTitle = new KDInputView
      name          : "title"
      label         : @labelTitle
      cssClass      : "warn-on-unsaved-data"
      placeholder   : "Give a title to your Tutorial..."
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Tutorial title is required!"

    @inputTutorialEmbedShowLink = new KDOnOffSwitch
      cssClass:"show-tutorial-embed"
      defaultState:off
      callback:(state)=>
        if state
          if @embedBox.hasValidContent
            @embedBox.show() unless "embed" in @embedBox.getEmbedHiddenItems()
            @embedBox.$().animate {top: "0px"}, 300
        else
          @embedBox.$().animate {top : "-400px"}, 300, =>
            @embedBox.hide()

    @inputTutorialEmbedLink = new KDInputView
      name          : "embed"
      label         : @labelEmbedLink
      cssClass      : "warn-on-unsaved-data tutorial-embed-link"
      placeholder   : "Please enter a URL to a video..."

      keyup :=>
        if @inputTutorialEmbedLink.getValue() is ""
          @embedBox.resetEmbedAndHide()

      paste :=>
          @utils.wait =>
            @inputTutorialEmbedLink.setValue @sanitizeUrls @inputTutorialEmbedLink.getValue()

            url = @inputTutorialEmbedLink.getValue().trim()

            if /^((http(s)?\:)?\/\/)/.test url
              # parse this for URL
              @embedBox.embedUrl url, {
                maxWidth: 540
                maxHeight: 200
              }, =>
                @embedBox.hide() if @inputTutorialEmbedShowLink.getValue() is off

    embedOptions = $.extend {}, options,
      delegate  : @
      hasConfig : yes
      forceType : "object"
      click:->
        no

    @embedBox = new EmbedBox embedOptions, data

    @inputContent = new KDInputViewWithPreview
      label       : @labelContent
      preview     : @preview
      name        : "body"
      cssClass    : "discussion-body warn-on-unsaved-data"
      type        : "textarea"
      autogrow    : yes
      placeholder : "Please enter your Tutorial content. (You can use markdown here)"
      validate    :
        rules     :
          required: yes
        messages  :
          required: "Tutorial body is required!"

    @cancelBtn = new KDButtonView
      title    : "Cancel"
      style    : "modal-cancel"
      callback : =>
        @reset()
        @parent.getDelegate().emit "ResetWidgets"

    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Post your Tutorial"
      type  : 'submit'

    @heartBox = new HelpBox
      subtitle : "About Tutorials"
      tooltip  :
        title  : "This is a public wall, here you can share your tutorials with the Koding community."

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

  click:(event)->
    # if $(event.target).parents("div.link-embed-box").length > 0
    #   #log "EMBED"
    # else
    #   #log "not EMBED"
    #   @embedBox.$().animate {top : "-400px"}, 300, =>
    #     @embedBox.hide()
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

  submit:=>
    @once "FormValidationPassed", => @reset()

    if @embedBox.hasValidContent
      @addCustomData "link", {
        link_cache: @embedBox.getEmbedCache()
        link_url : @embedBox.getEmbedURL()
        link_embed : @embedBox.getEmbedDataForSubmit()
        link_embed_hidden_items:@embedBox.getEmbedHiddenItems()
        link_embed_image_index:@embedBox.getEmbedImageIndex()
      }

    super

    @submitBtn.disable()
    @utils.wait 8000, => @submitBtn.enable()

  reset:=>
    @tagController.reset()
    @submitBtn.setTitle "Post your Tutorial"
    @removeCustomData "activity"
    @inputDiscussionTitle.setValue ''
    @inputContent.setValue ''
    @inputTutorialEmbedShowLink.setValue off
    @embedBox.resetEmbedAndHide()
    super

  viewAppended:()->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit Tutorial"
    @addCustomData "activity", activity
    {title, body, tags, link} = activity

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @inputDiscussionTitle.setValue Encoder.htmlDecode title
      @inputContent.setValue Encoder.htmlDecode body
      @inputTutorialEmbedLink.setValue Encoder.htmlDecode link?.link_url
      @inputContent.generatePreview()

    fillForm()

            # {{> @followupLink}}
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
          {{> @labelEmbedLink}}
          <div>
            {{> @inputTutorialEmbedLink}}
            {{> @inputTutorialEmbedShowLink}}
            {{> @embedBox}}
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