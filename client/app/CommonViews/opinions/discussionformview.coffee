class DiscussionFormView extends KDFormView

  constructor :(options, data)->

    super

    @preview = options.preview or {}

    {profile} = KD.whoami()

    @submitDiscussionBtn = new KDButtonView
      title           : "Save your changes"
      type            : "submit"
      cssClass        : "clean-gray discussion-submit-button"
      loader          :
        diameter      : 12

    @cancelDiscussionBtn = new KDButtonView
      title : "Cancel"
      cssClass:"modal-cancel discussion-cancel"
      type : "button"
      style: "modal-cancel"
      callback :=>
        @parent?.editDiscussionLink.$().click()

    @discussionBody = new KDInputViewWithPreview
      preview         : @preview
      cssClass        : "discussion-body"
      name            : "body"
      title           : "your Discussion Topic"
      type            : "textarea"
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
        KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

  viewAppended:->
    @setClass "update-options discussion"
    @setTemplate @pistachio()
    @template.update()

  submit:->
    # @once "FormValidationPassed", => @reset()
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
            {{> @submitDiscussionBtn}}
            {{> @cancelDiscussionBtn}}
          </div>
        </div>
      </div>
      """