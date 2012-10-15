class ActivityDiscussionWidget extends KDFormView

  constructor :->

    super

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

    @inputContent = new KDInputView
      label       : @labelContent
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
          content     : "<div class='modal-fullscreen-text'><textarea class='kdinput text' placeholder='What do you want to talk about? (You can use markdown here)' id='fullscreen-data'>"+@inputContent.getValue()+"</textarea></div>"
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
                @inputContent.setValue $("#fullscreen-data").val()
                modal.destroy()

        modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height()-12 # minus the margin, border pixels too..
        modal.$("#fullscreen-data").height modal.$(".kdmodal-content").height()-30
        modal.$("#fullscreen-data").width modal.$(".kdmodal-content").width()-40

    @heartBox = new HelpBox
      subtitle    : "About Code Sharing"
      tooltip     :
        title     : "Easily share your code with other members of the Koding community. Once you share, user can easily open or save your code to their own environment."

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
            {{> @fullScreenBtn}}
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