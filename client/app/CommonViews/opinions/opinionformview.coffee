class OpinionFormView extends KDFormView

  constructor :(options, data)->

    super

    {profile} = KD.whoami()

    @submitOpinionBtn = new KDButtonView
      title           : options.submitButtonTitle or "Post your reply"
      type            : "submit"
      cssClass        : "clean-gray opinion-submit-button"
      loader          :
        diameter      : 12

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
          content     : "<div class='modal-fullscreen-text'><textarea class='kdinput text' id='fullscreen-data'>"+@opinionBody.getValue()+"</textarea></div>"
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
                @opinionBody.setValue $("#fullscreen-data").val()
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

    @on "opinion.changeMarkdown", (value) ->
      # markdown switch implementation here

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
      <div class="opinion-box" id="opinion-form-box">
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
            {{> @fullScreenBtn}}
            {{> @submitOpinionBtn}}
          </div>
        </div>
      </div>
      """