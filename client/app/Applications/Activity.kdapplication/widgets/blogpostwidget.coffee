class ActivityBlogPostWidget extends KDFormView

  constructor :(options,data)->

    super options,data

    @preview = options.preview or {}

    @labelTitle = new KDLabelView
      title     : "New Blog Post"
      cssClass  : "first-label"

    @labelContent = new KDLabelView
      title : "Content:"

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @inputDiscussionTitle = new KDInputView
      name          : "title"
      label         : @labelTitle
      cssClass      : "warn-on-unsaved-data"
      placeholder   : "Give a title to what you want to your Blog Post..."
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Blog Post title is required!"

    @inputContent = new KDInputViewWithPreview
      label       : @labelContent
      preview     : @preview
      name        : "body"
      cssClass    : "discussion-body warn-on-unsaved-data"
      type        : "textarea"
      autogrow    : yes
      placeholder : "What do you want to talk about? (You can use markdown here)"
      validate    :
        rules     :
          required: yes
        messages  :
          required: "Blog Post body is required!"

    @cancelBtn = new KDButtonView
      title    : "Cancel"
      style    : "modal-cancel"
      callback : =>
        @reset()
        @parent.getDelegate().emit "ResetWidgets"

    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Post to your Blog"
      type  : 'submit'


    @heartBox = new HelpBox
      subtitle : "About Blog Posts"
      tooltip  :
        title  : "This is a public wall, here you can discuss anything with the Koding community."

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
        KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

  submit:->
    @once "FormValidationPassed", => @reset()
    super
    KD.track "Activity", "BlogPostSubmitted"
    @submitBtn.disable()
    @utils.wait 8000, => @submitBtn.enable()

  reset:->
    @submitBtn.setTitle "Start your Blog Post"
    @removeCustomData "activity"
    @inputDiscussionTitle.setValue ''
    @inputContent.setValue ''

    # deferred resets
    @utils.defer => @tagController.reset()

    super

  viewAppended:->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  switchToEditView:(activity,fake=no)->

    unless fake
      @submitBtn.setTitle "Edit Discussion"
      @addCustomData "activity", activity
    else
      @submitBtn.setTitle 'Submit again'

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