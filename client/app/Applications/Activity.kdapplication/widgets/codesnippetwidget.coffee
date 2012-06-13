class ActivityCodeSnippetWidget extends KDFormView
  
  constructor:->

    super

    @title = new KDInputView
      name          : "title"
      placeholder   : "Give a title to your code snippet..."
      validate      :
        rules       : 
          required  : yes
        messages    :
          required  : "Code snippet title is required!"

    @labelDescription = new KDLabelView
      title : "Description:"  

    @description = new KDInputView
      label       : @labelDescription
      name        : "body"
      placeholder : "What is your code about?"

    @labelContent = new KDLabelView
      title : "Code Snip:"

    @aceHolder = new KDView
      cssClass : "code-snip-holder"

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
      outputWrapper       : @selectedItemWrapper
      selectedItemsLimit  : 5
      listWrapperCssClass : "tags"
      form                : @
      itemDataPath        : "title"
      dataSource          : (args, callback)=>
        {inputValue} = args
        updateWidget = @getDelegate()
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback
    
    @tagAutoComplete = @tagController.getView()

  submit:=>

    @addCustomData "code", @ace.getContents()
    super

  reset:=>
    
    @title.setValue ''
    @description.setValue ''
    @ace.setContents "//your code snippet goes here..."
    @syntaxSelect.setValue 'javascript'
    @tagController.reset()

  widgetShown:->

    unless @ace
      @aceHolder.addSubView @loader = new KDLoaderView
        size          :
          width       : 30
          height      : 30
        loaderOptions :
          color       : "#ffffff"
          shape       : "spiral"
          diameter    : 30
          density     : 30
          range       : 0.4
          speed       : 1
          FPS         : 24
        click         : => @loadAce()
      @loadAce()
    else
      @refreshEditorView()
  
  snippetCount = 0

  loadAce:->

    @loader.show()
    @ace.destroy() if @ace
    @syntaxSelect.destroy() if @syntaxSelect
    
    @aceHolder.addSubView @ace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceHolder.addSubView @syntaxSelect = new KDSelectBox
      name          : "syntax"
      selectOptions : __aceSettings.syntaxes
      defaultValue  : "javascript"
      callback      : (value) => @emit "codeSnip.changeSyntax", value
  

    @ace.on "ace.ready", =>
      # @aceReady
      @loader.destroy()
      @ace.setShowGutter no
      @ace.setContents "//your code snippet goes here..."
      @ace.setTheme()
      @ace.setSyntax "javascript"
      @ace.editor.getSession().on 'change', => @refreshEditorView()
      @emit "codeSnip.aceLoaded"

    @on "codeSnip.changeSyntax", (syntax)=>
      @ace.setSyntax syntax

  refreshEditorView:->

    lines = @ace.editor.selection.doc.$lines
    lineAmount = if lines.length > 15 then 15 else if lines.length < 5 then 5 else lines.length
    @setAceHeightByLines lineAmount

  setAceHeightByLines: (lineAmount) ->

    lineHeight  = @ace.editor.renderer.lineHeight
    container   = @ace.editor.container
    height      = lineAmount * lineHeight
    @aceHolder.setHeight height = lineAmount * lineHeight + 20
    @ace.editor.resize()

  switchToEditView:(activity)->

    log activity
    {title, body} = activity
    {syntax, content} = activity.attachments[0]

    fillForm = =>
      @title.setValue Encoder.htmlDecode title 
      @description.setValue Encoder.htmlDecode body
      @ace.setContents Encoder.htmlDecode content
      @syntaxSelect.setValue Encoder.htmlDecode syntax

    if @ace?.editor
      fillForm()
    else
      @once "codeSnip.aceLoaded", => fillForm()
        

  viewAppended:()->

    @setClass "update-options codesnip"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder">
        <div class="formline">
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
          {{> @aceHolder}}
        </div>
        <div class="formline">
          {{> @labelAddTags}}
          <div>
            {{> @tagAutoComplete}}
            {{> @selectedItemWrapper}}
          </div>
        </div>
        <div class="formline submit">
          {{> @heartBox}}
          <div class="submit-box">
            {{> @cancelBtn}}{{> @submitBtn}}
          </div>
      </div>
    </div>
    """
