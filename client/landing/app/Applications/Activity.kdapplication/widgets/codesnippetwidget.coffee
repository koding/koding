class ActivityCodeSnippetWidget extends KDFormView

  constructor:->

    super

    @labelTitle = new KDLabelView
      title         : "Title:"
      cssClass      : "first-label"

    @title = new KDInputView
      name          : "title"
      cssClass      : "warn-on-unsaved-data"
      placeholder   : "Give a title to your code snippet..."
      validate      :
        rules       :
          required  : yes
          maxLength : 140
        messages    :
          required  : "Code snippet title is required!"

    @labelDescription = new KDLabelView
      title : "Description:"

    @description = new KDInputView
      label         : @labelDescription
      cssClass      : "warn-on-unsaved-data"
      name          : "body"
      placeholder   : "What is your code about?"
      validate      :
        rules       :
          maxLength : 3000

    @labelContent = new KDLabelView
      title : "Code Snip:"

    @hiddenAceInputClone = new KDInputView
      cssClass : 'hidden invisible'

    @aceWrapper = new KDView

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

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

    @loader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#ffffff"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @syntaxSelect = new KDSelectBox
      name          : "syntax"
      selectOptions : __aceSettings.getSyntaxOptions()
      defaultValue  : "javascript"
      callback      : (value) => @emit "codeSnip.changeSyntax", value

    @on "codeSnip.changeSyntax", (syntax)=>
      @updateSyntaxTag syntax
      @ace.setSyntax syntax

  updateSyntaxTag:(syntax)=>
    # Remove already appended syntax tag from submit queue if exists
    # FIXME It still fails for meta characters like /
    # oldSyntax = __aceSettings.syntaxAssociations[@ace.getSyntax()][0].toLowerCase()
    oldSyntax = @ace.getSyntax()
    subViews = @tagController.itemWrapper.getSubViews().slice()
    for item in subViews
      if item.getData().title is oldSyntax
        @tagController.removeFromSubmitQueue(item)
        break

    {selectedItemsLimit} = @tagController.getOptions()
    # Add new syntax tag to submit queue
    if @tagController.selectedItemCounter < selectedItemsLimit
      @tagController.addItemToSubmitQueue @tagController.getNoItemFoundView(syntax)

  submit:=>
    @addCustomData "code", @ace.getContents()
    @once "FormValidationPassed", => @reset()

    super

    @submitBtn.disable()
    @utils.wait 8000, => @submitBtn.enable()

  reset:=>
    @submitBtn.setTitle "Share your Code Snippet"

    @removeCustomData "activity"

    @title.setValue ''
    @description.setValue ''
    @syntaxSelect.setValue 'javascript'

    @updateSyntaxTag 'javascript'
    @hiddenAceInputClone.setValue ''
    @hiddenAceInputClone.unsetClass 'warn-on-unsaved-data'

    # deferred resets
    @utils.wait =>
      @tagController.reset()
      @ace.setContents "//your code snippet goes here..."
      @ace.setSyntax 'javascript'

  switchToEditView:(activity,fake=no)->
    unless fake
      @submitBtn.setTitle "Edit code snippet"
      @addCustomData "activity", activity
    else
      @submitBtn.setTitle 'Submit again'

    {title, body, tags} = activity
    {syntax, content} = activity.attachments[0]

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @title.setValue Encoder.htmlDecode title
      @description.setValue Encoder.htmlDecode body
      @ace.setContents Encoder.htmlDecode content
      @hiddenAceInputClone.setValue content
      @hiddenAceInputClone.setClass 'warn-on-unsaved-data'
      @syntaxSelect.setValue Encoder.htmlDecode syntax

    if @ace?.editor
      fillForm()
    else
      @once "codeSnip.aceLoaded", => fillForm()

  widgetShown:->

    unless @ace then @loadAce() else @refreshEditorView()

  snippetCount = 0

  loadAce:->

    @loader.show()

    @aceWrapper.addSubView @ace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceDefaultContent = "//your code snippet goes here..."

    @ace.on "ace.ready", =>
      @loader.destroy()
      @ace.setShowGutter no
      @ace.setContents @aceDefaultContent
      @ace.setTheme()
      @ace.setFontSize(12, no)
      @ace.setSyntax "javascript"
      @ace.editor.getSession().on 'change', =>

        # Shadowing the Ace contents so the onbeforeunload catch-all does
        # not need special jquery calls

        @hiddenAceInputClone.setValue @ace.getContents()
        unless @hiddenAceInputClone.getValue() in ['',@aceDefaultContent]
          @hiddenAceInputClone.setClass "warn-on-unsaved-data"
        else
          @hiddenAceInputClone.unsetClass "warn-on-unsaved-data"

        @refreshEditorView()
      @emit "codeSnip.aceLoaded"

  refreshEditorView:->
    lines = @ace.editor.selection.doc.$lines
    lineAmount = if lines.length > 15 then 15 else if lines.length < 5 then 5 else lines.length
    @setAceHeightByLines lineAmount

  setAceHeightByLines: (lineAmount) ->
    lineHeight  = @ace.editor.renderer.lineHeight
    container   = @ace.editor.container
    height      = lineAmount * lineHeight
    @$('.code-snip-holder').height height + 20
    @ace.editor.resize()

  viewAppended:()->

    @setClass "update-options codesnip"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder">
        <div class="formline">
          {{> @labelTitle}}
          <div>
            {{> @title}}
          </div>
        </div>
        <div class="formline">
          {{> @labelDescription}}
          <div>
            {{> @description}}
          </div>
        </div>
        <div class="formline">
          {{> @labelContent}}
          <div class="code-snip-holder">
            {{> @loader}}
            {{> @aceWrapper}}
            {{> @hiddenAceInputClone}}
            {{> @syntaxSelect}}
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
