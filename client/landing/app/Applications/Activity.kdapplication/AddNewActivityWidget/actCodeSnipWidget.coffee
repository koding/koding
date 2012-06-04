class ActivityCodeSnippetWidget extends KDFormView

  constructor:->

    super

    @inputCodeSnipTitle = new KDInputView
      name          : "title"
      placeholder   : "Give a title to your code snippet..."
      validate      :
        rules       : 
          required  : yes
        messages    :
          required  : "Code snippet title is required!"

    @inputCodeSnipTitle.registerListener
      KDEventTypes  : "focus"
      listener      : @
      callback      : -> #formline1.setClass 'focus'

    @inputCodeSnipTitle.registerListener
      KDEventTypes  : "blur"
      listener      : @
      callback      : -> #formline1.unsetClass 'focus'

    @labelDescription = new KDLabelView
      title : "Description:"  

    @inputDescription = new KDInputView
      label       : @labelDescription
      name        : "body"
      placeholder : "What is your code about?"

    @labelContent = new KDLabelView
      title : "Code Snip:"

    @aceHolder = new KDView
      cssClass : "code-snip-holder dark-select"

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @cancelBtn = new KDButtonView
      title : "Cancel"
      style : "modal-cancel"
      callback  :(event)=>
        event.stopPropagation()
        event.preventDefault()
        @reset()
  
    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Share your Code Snippet"
      type  : 'submit'
  
    @heartBox = new HelpBox
      subtitle    : "About Code Sharing" 
      tooltip     :
        title     : "Easily share your code with other members of the Koding community. Once you share, user can easily open or save your code to their own environment."
        placement : "above"
        offset    : 0
        delayIn   : 300
        html      : yes
        animate   : yes

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
        updateWidget.propagateEvent KDEventType : "AutoCompleteNeedsTagData", {inputValue,blacklist,callback}
    
    @tagAutoComplete = @tagController.getView()
    
    @labelSyntax = new KDLabelView
      title : "Syntax:"

    @syntaxSelect = new KDSelectBox
      name          : "syntax"
      selectOptions : __aceSettings.syntaxes
      defaultValue  : "javascript"
      callback      : (value) => @emit "codeSnip.changeSyntax", value
    
  
  submit:=>

    @addCustomData "code", @ace.getContents()
    super

  reset:=>

    @inputCodeSnipTitle.setValue ''
    @inputDescription.setValue ''
    @syntaxSelect.setValue 'javascript'
    @tagController.reset()
    @ace.setContents "//your code snippet goes here..."
    @getDelegate().handleEvent type: 'ActivityUpdateWidgetShouldReset'

  widgetShown:->

    unless @ace
      @aceHolder.addSubView loader = new KDLoaderView
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
      loader.show()

      @aceHolder.addSubView @ace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet.txt"

      @ace.on "ace.ready", =>
        loader.destroy()
        @ace.setTheme()
        @ace.setSyntax()
        @ace.setContents "//your code snippet goes here..."
      
      @on "codeSnip.changeSyntax", (syntax)=>
        @ace.setSyntax syntax

    # @ace.refreshEditorView()

  viewAppended:()->
    @setClass "update-options codesnip"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="form-headline">{{> @inputCodeSnipTitle}}</div>
    <div class="form-actions-mask">
      <div class="form-actions-holder">
        <div class="formline">
          {{> @labelDescription}}
          <div>
            {{> @inputDescription}}
          </div>
        </div>
        <div class="formline">
          {{> @labelContent}}
          {{> @aceHolder}}
        </div>
        <div class="formline">
          {{> @labelSyntax}}
          <div class="ov">
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
          {{> @heartBox}}
          <div class="submit-box">
            {{> @cancelBtn}}{{> @submitBtn}}
          </div>
      </div>
    </div>
    """
