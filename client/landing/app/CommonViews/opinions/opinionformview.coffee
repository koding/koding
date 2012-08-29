class OpinionFormView extends KDFormView

  constructor :(options, data)->

    super

    {profile} = KD.whoami()

    @submitOpinionBtn = new KDButtonView
      title           : "Post your reply"
      type            : "submit"
      cssClass        : "clean-gray opinion-submit"

    @opinionBody = new KDInputView
      cssClass        : "opinion-body"
      name            : "body"
      title           : "your Opinion"
      type            : "textarea"
      autogrow        : yes
      placeholder     : "What do you want to contribute to the discussion?"

    @labelAddTags = new KDLabelView
      title           : "Add Tags:"

    @selectedItemWrapper = new KDCustomHTMLView
      tagName         : "div"
      cssClass        : "tags-selected-item-wrapper clearfix"

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
          <span class="supports-markdown">You can use markdown syntax here</span>
          {{> @opinionBody}}
        </div>
        <div>
          {{> @labelAddTags}}
          <div>
            {{> @selectedItemWrapper}}
            {{> @tagAutoComplete}}
          </div>
        </div>
        <div>
        {{> @submitOpinionBtn}}
        </div>
      </div>
      """