class OpinionFormView extends KDFormView

  constructor :(options, data)->

    super

    {profile} = KD.whoami()

    @submitOpinionBtn = new KDButtonView
      title           : options.submitButtonTitle or "Post your reply"
      type            : "submit"
      cssClass        : "clean-gray opinion-submit-button"

    @opinionBody = new KDInputView
      cssClass        : "opinion-body"
      name            : "body"
      title           : "your Opinion"
      type            : "textarea"
      # autogrow        : yes
      placeholder     : "What do you want to contribute to the discussion?"

    @labelAddTags = new KDLabelView
      title           : "Add Tags:"

    @selectedItemWrapper = new KDCustomHTMLView
      tagName         : "div"
      cssClass        : "tags-selected-item-wrapper clearfix"

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

    # @fullscreenLink = new KDCustomHTMLView
    #   tagName     : 'a'
    #   name        : "fullscreenLink"
    #   value       : "go fullscreen"
    #   attributes  :
    #     title     : "go fullscreen"
    #     href      : '#'
    #     value     : "go fullscreen"
    #   cssClass    : 'mfullscreen-link'
    #   partial     : "go fullscreen"
    #   click       :->
    #     modal = new KDModalView
    #       title          : "Your reply here"
    #       content        :
    #       height         : "auto"
    #       overlay        : yes
    #       buttons        :
    #         Okay       :
    #           style      : "modal-clean-gray"
    #           loader     :
    #             color    : "#ffffff"
    #             diameter : 16
    #           callback   : =>
    #             modal.buttons.Okay.hideLoader()
    #             modal.destroy()

    @markdownSelect = new KDSelectBox
      type          : "select"
      name          : "markdown"
      cssClass      : "select markdown-select hidden"
      selectOptions :
          [
              title     : "enable markdown syntax"
              value     : "markdown"
            ,
              title     : "disable markdown syntax"
              value     : "nomarkdown"
          ]
      defaultValue  : "markdown"
      callback      : (value) =>
        @emit "opinion.changeMarkdown", value

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


    if data instanceof bongo.api.JOpinion
      @opinionBody.setValue Encoder.htmlDecode data.body

    @on "opinion.changeMarkdown", (value) ->

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

    @setClass "update-options opinion"
    @setTemplate @pistachio()
    @template.update()

  submit:=>
    @once "FormValidationPassed", => @reset()
    super

  pistachio:->
      """
      <div class="opinion-box">
        <div class="opinion-form">
          {{> @markdownSelect}}
          {{> @opinionBody}}
        </div>
        <div class="opinion-buttons">
          <div class="opinion-heart-box">
            {{> @heartBox}}
          </div>
          <div class="opinion-submit">
            {{> @markdownLink}}
            {{> @submitOpinionBtn}}
          </div>
        </div>
      </div>
      """