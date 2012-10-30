class ActivityLinkWidget extends KDFormView

  constructor:->

    super

    @labelTitle = new KDLabelView
      title         : "Title:"
      cssClass      : "first-label"

    @title = new KDInputView
      name          : "title"
      placeholder   : "Give a title to your link..."
      validate      :
        rules       :
          required  : yes
          maxLength : 140
        messages    :
          required  : "Link title is required!"

    @labelDescription = new KDLabelView
      title : "Description:"
      autogrow: yes

    @description = new KDInputView
      label         : @labelDescription
      name          : "body"
      placeholder   : "What is your link about? Leave empty to display your links embedded description"
      validate      :
        rules       :
          maxLength : 3000

    @labelLink = new KDLabelView
      title : "Link:"

    @embedBox = new EmbedBox

    @previousLink = ''
    @link = new KDInputView
      name          : "link_url"
      placeholder   : "Please input the URL here..."
      validate      :
        rules       :
          required  : yes
          maxLength : 140
        messages    :
          required  : "Link URL is required!"
      blur:=>
        unless @link.getValue() is @previousLink
          @previousLink = @link.getValue()

          @embedBox.embedUrl @link.getValue(), {}, (linkData)=>

            @labelTitle.show()
            @labelDescription.show()
            @title.show()
            @description.show()

            @title.setValue linkData.title
            @description.setValue linkData.description
            @removeCustomData 'link_embed'
            @addCustomData 'link_embed', linkData


    @cancelBtn = new KDButtonView
      title    : "Cancel"
      style    : "modal-cancel"
      callback : =>
        @reset()
        @parent.getDelegate().emit "ResetWidgets"

    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Share your Code Snippet"
      type  : 'submit'

    @heartBox = new HelpBox
      subtitle    : "About Code Sharing"
      tooltip     :
        title     : "Easily share your code with other members of the Koding community. Once you share, user can easily open or save your code to their own environment."

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @selectedItemWrapper = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "tags-selected-item-wrapper clearfix"

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



  submit:=>
    @once "FormValidationPassed", => @reset()
    super

  reset:=>
    @submitBtn.setTitle "Share your Link"
    @removeCustomData "activity"
    @title.setValue ''
    @description.setValue ''
    @link.setValue ''

    @embedBox.clearEmbed()

    @tagController.reset()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit link"
    @addCustomData "activity", activity
    {title, body, tags, link_url, link_embed} = activity

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    @title.setValue Encoder.htmlDecode title
    @description.setValue Encoder.htmlDecode body

    @embedBox.embedUrl link_url


  widgetShown:->

  viewAppended:()->

    @setClass "update-options link"
    @setTemplate @pistachio()
    @template.update()

    @labelTitle.hide()
    @labelDescription.hide()
    @description.hide()
    @title.hide()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder">
        <div class="formline link-title">
          {{> @labelTitle}}
          <div>
            {{> @title}}
          </div>
        </div>
        <div class="formline link-description">
          {{> @labelDescription}}
          <div>
            {{> @description}}
          </div>
        </div>
        <div class="formline">
          {{> @labelLink}}
          <div class="link-wrapper">
            {{> @link}}
            {{> @embedBox}}
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
