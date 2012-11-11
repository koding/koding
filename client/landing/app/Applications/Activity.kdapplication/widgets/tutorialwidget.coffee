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
      placeholder   : "Please enter a URL to a video..."

      paste :=>
          @utils.wait =>

            @inputTutorialEmbedLink.setValue @sanitizeUrls @inputTutorialEmbedLink.getValue()

            url = @inputTutorialEmbedLink.getValue()

            if /^((http(s)?\:)?\/\/)/.test url
              # parse this for URL
              @embedBox.embedUrl url, {
                maxWidth: 540
                maxHeight: 200
              }, =>
                @embedBox.hide()

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
      cssClass    : "discussion-body"
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

    @fullScreenBtn = new KDButtonView
      style           : "clean-gray"
      icon            : yes
      iconClass       : "fullscreen"
      iconOnly        : yes
      cssClass        : "fullscreen-button"
      title           : "Fullscreen Edit"
      tooltip         :
        title         : "Fullscreen Edit"
      callback: =>
        @textContainer = new KDView
          cssClass:"modal-fullscreen-text"

        @text = new KDInputViewWithPreview
          type : "textarea"
          cssClass : "fullscreen-data kdinput text"
          defaultValue : @inputContent.getValue()

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
      click       : (pubInst, event)=>
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
      subtitle : "About Tutorials"
      tooltip  :
        title  : "This is a public wall, here you can share your tutorials with the Koding community."
      # click :->
      #   modal = new KDModalView
      #     title          : "Additional information on Tutorials"
      #     content        : "<div class='modalformline signature'><h3>Hi!</h3><p>Anything odd? Drop me a message.</p><p>--@arvidkahl</p></div>"
      #     height         : "auto"
      #     overlay        : yes
      #     buttons        :
      #       Okay       :
      #         style      : "modal-clean-gray"
      #         loader     :
      #           color    : "#ffffff"
      #           diameter : 16
      #         callback   : =>
      #           modal.buttons.Okay.hideLoader()
      #           modal.destroy()

    @followupLink = new KDCustomHTMLView
      tagName : "a"
      attributes :
        title : "If your tutorial is a followup, then select the previous video here."
        href : "#"
      cssClass : "followup-link"
      partial : "Select a related Tutorial"
      click:=>

        modal = new KDModalView
          title : "Select the previous Tutorial"
          content : ""
          cssClass : "modal-select-tutorials"
          height:400
          width:600
          overlay: yes
          buttons :
            Select :
              style : "modal-clean-gray"
              callback: =>
                modal.destroy()

        createFeed = (view)=>
          appManager.tell 'Feeder', 'createContentFeedController', {
            itemClass             : SelectableActivityListItemView
            listControllerClass   : ActivityListController
            listCssClass          : "activity-related"
            noItemFoundText       : "You have not posted a Tutorial yet."
            limitPerPage          : 8
            delegate : @
            filter                :
              Tutorials          :
                title             : "Tutorials"
                optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
                dataSource        : (selector, options, callback)=>
                  if @_searchValue

                    selector.originId = KD.whoami().getId()
                    selector.type = $in: [
                      'CTutorialActivity'
                    ]
                    selector.snapshot = {$regex : ".*#{@_searchValue}.*", $options : "i"}
                    appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
                      callback null, data
                    # # KD.remote.api.JTutorial.byRelevance @_searchValue, options, callback
                  else
                    selector.originId = KD.whoami().getId()
                    selector.type = $in: [
                      'CTutorialActivity'
                    ]
                    appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
                      callback null, data
            sort                  :
              'sorts.likesCount'  :
                title             : "Most popular"
                direction         : -1
              'modifiedAt'        :
                title             : "Latest activity"
                direction         : -1
              'sorts.repliesCount':
                title             : "Most activity"
                direction         : -1
              # and more
          }, (controller)=>
            #put listeners here, look for the other feeder instances

            # unless KD.isMine account
            #   @listenTo
            #     KDEventTypes       : "mouseenter"
            #     listenedToInstance : controller.getView()
            #     callback           : => @mouseEnterOnFeed()
            # log controller
           @_lastSubView = controller.getView()

           view.addSubView @_lastSubView
           @_lastSubView.on "setSelectedData", (selectedData)=>
             @selectedData = selectedData
             @followupLink.updatePartial "Linked with '"+selectedData.title+"'"

        loadView = (mainView, firstRun = yes)=>
          if firstRun
            mainView.on "searchFilterChanged", (value) =>
              return if value is @_searchValue
              @_searchValue = value
              @_lastSubView.destroy?()
              loadView mainView, no
            mainView.addSubView header = new HeaderViewSection type : "small", title : "Tutorials"
            header.setSearchInput()

          createFeed mainView

        loadView modal, yes


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

    if @selectedData?
      @addCustomData "appendToList", @selectedData

    super

  reset:=>
    @tagController.reset()
    @submitBtn.setTitle "Post your Tutorial"
    @removeCustomData "activity"
    @inputDiscussionTitle.setValue ''
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
            <div class="discussion-widget-content">
            {{> @followupLink}}
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