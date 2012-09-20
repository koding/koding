class ActivityCodeShareWidget extends KDFormView

  constructor:->

    super

    @labelTitle = new KDLabelView
      title         : "Title:"
      cssClass      : "first-label"

    @title = new KDInputView
      name          : "title"
      placeholder   : "Give a title to your code ..."
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Code title is required!"

    @labelDescription = new KDLabelView
      title : "Description:"

    @description = new KDInputView
      label       : @labelDescription
      name        : "body"
      placeholder : "What is your code about?"

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
      title : "Post your Code Share"
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
        appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

    @labelHTMLContent = new KDLabelView
      title : "HTML Options"
      cssClass : "settings-label"

    @aceHTMLWrapper = new KDView

    @HTMLloader = new KDLoaderView
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

    @isWideScreen = no

    @wideScreenBtn = new KDButtonView
      style           : "clean-gray"
      cssClass        : ""
      title           : "Increase Editor Size"
      callback: =>
        # crude size estimation
        viewport = $(window).height()
        wideScreenHeight = viewport / 2

        if @isWideScreen
          @unsetWideScreen wideScreenHeight
        else
          @setWideScreen wideScreenHeight

    @labelCSSContent = new KDLabelView
      title : "CSS Options"
      cssClass : "settings-label"

    @aceCSSWrapper = new KDView

    @CSSloader = new KDLoaderView
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

    @labelJSContent = new KDLabelView
      title : "JavaScript Options"
      cssClass : "settings-label"

    @aceJSWrapper = new KDView

    @JSloader = new KDLoaderView
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

    @codeShareResultView = new CodeShareResultView {}, {}
    @codeShareResultView.hide()

    @codeShareResultButton = new KDButtonView
      title: "Run this Code Share"
      cssClass:"clean-gray result-button"
      click:=>
        @codeShareResultButton.setTitle "Refresh Code Share"
        @codeShareResultView.show()
        @codeShareCloseButton.show()

        @resultBanner.hide()

        ## checkbox debug ## log "csw::resultButton:click (@libCSSPrefix.getValue()):",@libCSSPrefix.getValue(), "(@libCSSPrefix):",@libCSSPrefix

        @codeShareResultView.emit "CodeShareSourceHasChanges",
        {
          attachments:[
            {
              content:@HTMLace.getContents()
              title:"irrelevant"
              syntax:"html"},
            {
              content:@CSSace.getContents()
              title:"irrelevant"
              syntax:"css"
              },
            {
              content:@JSace.getContents()
              title:"irrelevant"
              syntax:"javascript"
            }
            ]

          classesHTML:@libHTMLClasses.getValue()
          extrasHTML:@libHTMLHeadExtras.getValue()
          externalCSS:@libCSSExternal.getValue()
          externalJS:@libJSExternal.getValue()

          modeHTML : @libHTMLSelect.getValue()
          modeCSS  : @libCSSSelect.getValue()
          modeJS   : @libJSSelect.getValue()

          resetsCSS : if @$("input[name=prefixCSSCheck]").prop("checked") is yes then "on" else "off"
          prefixCSS : @libCSSPrefix.getValue()

          modernizeJS : if @$("input[name=modernizeJSCheck]").prop("checked") is yes then "on" else "off"
          libsJS : @libJSSelectLibs.getValue()

          }

        @codeShareContainer.showPane @codeShareResultPane


    @codeShareCloseButton = new KDButtonView
      title: "Stop and Close this Code Share"
      cssClass:"clean-gray hidden"
      click:=>
        @codeShareResultView.hide()
        @codeShareResultView.resetResultFrame()
        @codeShareResultButton.setTitle "Run this Code Share"
        @codeShareCloseButton.hide()

        @resultBanner.show()

    @resultBanner = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "result-banner"
      partial     : ""

    @resultBannerButton = new KDCustomHTMLView
      name              : "resultBannerButton"
      tagName           : "a"
      attributes        :
        href            : "#"
      partial           : "Click here to see this Code Share!"
      cssClass          : "result-banner-button"
      click             : =>
        @codeShareResultButton.setTitle "Reset Code Share"
        @codeShareResultView.show()
        @resultBanner.hide()
        @codeShareCloseButton.show()
        @codeShareResultView.emit "CodeShareSourceHasChanges",
        {
          attachments:[
            {
              content:@HTMLace.getContents()
              title:"irrelevant"
              syntax:"html"},
            {
              content:@CSSace.getContents()
              title:"irrelevant"
              syntax:"css"
              },
            {
              content:@JSace.getContents()
              title:"irrelevant"
              syntax:"javascript"
            }
            ]

          classesHTML:@libHTMLClasses.getValue()
          extrasHTML:@libHTMLHeadExtras.getValue()
          externalCSS:@libCSSExternal.getValue()
          externalJS:@libJSExternal.getValue()

          modeHTML : @libHTMLSelect.getValue()
          modeCSS  : @libCSSSelect.getValue()
          modeJS   : @libJSSelect.getValue()

          resetsCSS : if @$("input[name=prefixCSSCheck]").prop("checked") is yes then "on" else "off"
          prefixCSS : @libCSSPrefix.getValue()

          modernizeJS : if @$("input[name=modernizeJSCheck]").prop("checked") is yes then "on" else "off"
          libsJS : @libJSSelectLibs.getValue()

          }

    @resultBanner.addSubView @resultBannerButton


## LIBRARY OVERLAYS

    @labelHTMLSelect = new KDLabelView
      title : "Markup:"
    @labelHTMLClasses = new KDLabelView
      title : "&lt;html&gt; Classes:"
    @labelHTMLExtras = new KDLabelView
      title : "&lt;head&gt; Elements:"
    @labelCSSSelect = new KDLabelView
      title : "Stylesheet:"
    @labelCSSPrefix = new KDLabelView
      title : "Use PrefixFree"
      cssClass : "legend-for-checkbox"
    @labelCSSResets = new KDLabelView
      title : "Use CSS Reset"
      cssClass : "legend-for-radios"
    @labelCSSExternals = new KDLabelView
      title : "External Stylesheets:"
    @labelJSSelect = new KDLabelView
      title : "Script:"
    @labelJSModernizr = new KDLabelView
      title : "Use Modernizr"
      cssClass : "legend-for-checkbox"
    @labelJSLibraries = new KDLabelView
      title : "Select JS Libraries:"
    @labelJSExternals = new KDLabelView
      title : "External Scripts:"
      cssClass : "legend-for-text"

    @librariesHTMLContainer = new KDView
      cssClass : "libs-container libs-html"

    @librariesCSSContainer = new KDView
      cssClass : "libs-container libs-css"

    @librariesJSContainer = new KDView
      cssClass : "libs-container libs-js"

    @librariesHTMLContent = new KDView
      cssClass : "libs-box"

    @librariesCSSContent = new KDView
      cssClass : "libs-box"

    @librariesJSContent = new KDView
      cssClass : "libs-box"

    @libHTMLSelect = new KDSelectBox
      title : "HTML Modes"
      label : @labelHTMLSelect
      name  : "modeHTML"
      height: 12
      selectOptions:
        [
          {
            title:"HTML"
            value:"html"
          }
          {
            title:"Markdown"
            value:"markdown"
          }
        ]

    @libCSSSelect = new KDSelectBox
      title : "CSS Modes"
      name  : "modeCSS"
      label : @labelCSSSelect
      selectOptions:
        [
          {
            title:"CSS"
            value:"css"
          }
        ]

    @libJSSelect = new KDSelectBox
      title : "JS Modes"
      name  : "modeJS"
      selectOptions:
        [
          {
            title:"JavaScript"
            value:"javascript"
          }
          {
            title:"CoffeeScript"
            value:"coffee"
          }
        ]

    @libHTMLClasses = new KDInputView
      name : "classesHTML"
      label : @labelHTMLClasses
      cssClass : "libs-html-input"
      placeholder : "extra html classes"

    @libHTMLHeadExtras = new KDInputView
      name : "extrasHTML"
      label: @labelHTMLExtras
      cssClass : "libs-html-input"
      placeholder : "extra head tags"

    @libCSSExternal = new KDInputView
      name : "externalCSS"
      label : @labelCSSExternals
      cssClass : "libs-html-input"
      placeholder : "external css files"

    @libJSExternal = new KDInputView
      name : "externalJS"
      cssClass : "libs-html-input"
      placeholder : "external JS files"

    @libCSSPrefix = new KDInputView
      type : "checkbox"
      name : "prefixCSSCheck"
      label : @labelCSSPrefix
      cssClass : "libs-css-checkbox"
      title : "PrefixFree"
      partial : "PrefixFree"

    @libCSSResets = new KDInputRadioGroup
      name : "resetsCSS"
      label : @labelCSSResets
      title: "CSS Resets"
      radios: [
        {
          title:"Reset"
          value:"reset"
        }
        {
          title:"Normalize"
          value:"normalize"
        }
        {
          title:"None"
          value:"none"
        }
      ]

    @libJSSelectLibs = new KDSelectBox
      title : "JS Libraries"
      name  : "libsJS"
      selectOptions:
        "no additional Library":
          [
            {
              title:"none (JQuery-latest is always included)"
              value:"none"
            }
          ]
        "jQuery":
          [
            {
              title:"JQuery latest with JQuery UI (1.8.23)"
              value:"jquery-latest-with-ui-1-8-23"
            }
          ]
        "MooTools":
          [
            {
              title:"MooTools (1.4.5)"
              value:"mootools-1-4-5"
            }
          ]
        "Dojo":
          [
            {
              title:"Dojo (1.8.0)"
              value:"dojo-1-8-0"
            }
          ]
        "Ext Core":
          [
            {
              title:"Ext Core (3.1.0)"
              value:"ext-core-3-1-0"
            }
          ]
        "Prototype":
          [
            {
              title:"Prototype (1.7.1.0)"
              value:"prototype-1-7-1-0"
            }
          ]
        "script.aculo.us":
          [
            {
              title:"script.aculo.us (1.9.0)"
              value:"scriptaculous-1-9-0"
            }
          ]

    @libJSModernizr = new KDInputView
      type : "checkbox"
      name : "modernizeJSCheck"
      cssClass : "libs-js-checkbox"
      title : "Modernizr"
      partial : "Modernizr"


    @librariesHTMLContent.addSubView @labelHTMLSelect
    @librariesHTMLContent.addSubView @libHTMLSelect
    @librariesHTMLContent.addSubView @labelHTMLClasses
    @librariesHTMLContent.addSubView @libHTMLClasses
    @librariesHTMLContent.addSubView @labelHTMLExtras
    @librariesHTMLContent.addSubView @libHTMLHeadExtras

    @librariesCSSContent.addSubView @labelCSSSelect
    @librariesCSSContent.addSubView @libCSSSelect
    @librariesCSSContent.addSubView @libCSSPrefix
    @librariesCSSContent.addSubView @labelCSSPrefix
    @librariesCSSContent.addSubView @labelCSSResets
    @librariesCSSContent.addSubView @libCSSResets
    @librariesCSSContent.addSubView @labelCSSExternals
    @librariesCSSContent.addSubView @libCSSExternal

    @librariesJSContent.addSubView @labelJSSelect
    @librariesJSContent.addSubView @libJSSelect
    @librariesJSContent.addSubView @labelJSLibraries
    @librariesJSContent.addSubView @libJSSelectLibs
    @librariesJSContent.addSubView @libJSModernizr
    @librariesJSContent.addSubView @labelJSModernizr
    @librariesJSContent.addSubView @labelJSExternals
    @librariesJSContent.addSubView @libJSExternal

    @librariesHTMLContainer.addSubView @librariesHTMLContent
    @librariesCSSContainer.addSubView @librariesCSSContent
    @librariesJSContainer.addSubView @librariesJSContent

    @labelHTMLContent.$().hover =>
      @$("div.libs-html").css "opacity":1
      @$("div.libs-html").css "z-index":100

    , =>
      @$("div.libs-html").hover =>
        noop
      , =>
        @$("div.libs-html").css "opacity":0
        @$("div.libs-html").css "z-index":-1

    @labelCSSContent.$().hover =>
      @$("div.libs-css").css "opacity":1
      @$("div.libs-css").css "z-index":100
    , =>
      @$("div.libs-css").hover =>
        noop
      , =>
        @$("div.libs-css").css "opacity":0
        @$("div.libs-css").css "z-index":-1

    @labelJSContent.$().hover =>
      @$("div.libs-js").css "opacity":1
      @$("div.libs-js").css "z-index":100
    , =>
      @$("div.libs-js").hover =>
        noop
      , =>
        @$("div.libs-js").css "opacity":0
        @$("div.libs-js").css "z-index":-1

    @codeShareContainer = new KDTabView
      cssClass: "code-share-container"

    # iframe Tab

    @codeShareResultPane = new KDTabPaneView
      name:"Code Share"
      cssClass: "result-pane"

    @codeShareResultPane.addSubView @resultBanner
    @codeShareResultPane.addSubView @codeShareResultView

    # HTML Tab

    @codeShareHTMLPane = new KDTabPaneView
      name:"HTML"

    @codeShareHTMLCodeSnipContainer = new KDCustomHTMLView
      tagName : "div"
      cssClass :"code-snip-container"

    @codeShareHTMLCodeSnipContainer.addSubView @labelHTMLContent
    @codeShareHTMLCodeSnipContainer.addSubView @librariesHTMLContainer

    @codeShareHTMLPane.addSubView @codeShareHTMLCodeSnipContainer

    @codeShareHTMLCodeSnipHolder = new KDCustomHTMLView
      tagName:"div"
      cssClass : "code-snip-holder share"

    @codeShareHTMLCodeSnipHolder.addSubView @HTMLloader
    @codeShareHTMLCodeSnipHolder.addSubView @aceHTMLWrapper

    @codeShareHTMLCodeSnipContainer.addSubView @codeShareHTMLCodeSnipHolder

    # CSS Tab

    @codeShareCSSPane = new KDTabPaneView
      name:"CSS"

    @codeShareCSSCodeSnipContainer = new KDCustomHTMLView
      tagName : "div"
      cssClass :"code-snip-container"

    @codeShareCSSCodeSnipContainer.addSubView @labelCSSContent
    @codeShareCSSCodeSnipContainer.addSubView @librariesCSSContainer

    @codeShareCSSPane.addSubView @codeShareCSSCodeSnipContainer

    @codeShareCSSCodeSnipHolder = new KDCustomHTMLView
      tagName:"div"
      cssClass : "code-snip-holder share"

    @codeShareCSSCodeSnipHolder.addSubView @CSSloader
    @codeShareCSSCodeSnipHolder.addSubView @aceCSSWrapper

    @codeShareCSSCodeSnipContainer.addSubView @codeShareCSSCodeSnipHolder

    # JS Tab

    @codeShareJSPane = new KDTabPaneView
      name:"JavaScript"

    @codeShareJSCodeSnipContainer = new KDCustomHTMLView
      tagName : "div"
      cssClass :"code-snip-container"

    @codeShareJSCodeSnipContainer.addSubView @labelJSContent
    @codeShareJSCodeSnipContainer.addSubView @librariesJSContainer

    @codeShareJSPane.addSubView @codeShareJSCodeSnipContainer

    @codeShareJSCodeSnipHolder = new KDCustomHTMLView
      tagName:"div"
      cssClass : "code-snip-holder share"

    @codeShareJSCodeSnipHolder.addSubView @JSloader
    @codeShareJSCodeSnipHolder.addSubView @aceJSWrapper

    @codeShareJSCodeSnipContainer.addSubView @codeShareJSCodeSnipHolder

    @codeShareContainer.addPane @codeShareResultPane
    @codeShareContainer.addPane @codeShareHTMLPane
    @codeShareContainer.addPane @codeShareCSSPane
    @codeShareContainer.addPane @codeShareJSPane

    @codeShareResultPane.hideTabCloseIcon()
    @codeShareHTMLPane.hideTabCloseIcon()
    @codeShareCSSPane.hideTabCloseIcon()
    @codeShareJSPane.hideTabCloseIcon()

    # hover switching enabled by default
    @codeShareContainer.$(".kdtabhandle").hover (event)=>
      $(event.target).closest(".kdtabhandle").click()
      @HTMLace.editor.resize()
      @CSSace.editor.resize()
      @JSace.editor.resize()
    , noop

    @codeShareContainer.showPane @codeShareResultPane


  unsetWideScreen:(wideScreenHeight)=>

          @$(".formline-codeshare").css "margin-left":"168px"
          @$(".formline-codeshare").css "margin-right":"0px"
          @$(".code-snip-container").css "max-width":"560px"
          @$(".formline-codeshare").css "max-width":"560px"
          @$(".code-snip-container").css "height":"300px"
          @$(".code-share-container").css "height":(340)+"px"
          @$(".code-snip-holder.share").css "height":300+"px"
          @$(".kdview.result-pane").css "height":300+"px"
          @$(".formline-codeshare").css "height":"340px"

          @HTMLace.editor.resize()
          @CSSace.editor.resize()
          @JSace.editor.resize()

          @isWideScreen = no
          @wideScreenBtn.setTitle "Increase Editor Size"

  setWideScreen:(wideScreenHeight)=>
          @$(".formline-codeshare").css "margin-left":"10px"
          @$(".formline-codeshare").css "margin-right":"10px"
          @$(".code-snip-container").css "max-width":"100%"
          @$(".formline-codeshare").css "max-width":"100%"
          @$(".code-snip-container").css "height":wideScreenHeight+"px"
          @$(".code-share-container").css "height":(40+wideScreenHeight)+"px"
          @$(".code-snip-holder.share").css "height":wideScreenHeight+"px"
          @$(".kdview.result-pane").css "height":wideScreenHeight+"px"
          @$(".formline-codeshare").css "height":(40+wideScreenHeight)+"px"

          @HTMLace.editor.resize()
          @CSSace.editor.resize()
          @JSace.editor.resize()

          @isWideScreen = yes
          @wideScreenBtn.setTitle "Reduce Editor Size"

  submit:=>

    ## checkbox debug ## log "csw::submit/pre (@getData().prefixCSSCheck):",@getData().prefixCSSCheck," (@getData().prefixCSS):",@getData().prefixCSS
    if not (@getData().prefixCSSCheck?) or (@getData().prefixCSS is "off")
      @addCustomData "prefixCSS", "off"
    else
      @addCustomData "prefixCSS", "on"

    if not (@getData().modernizeJSCheck?) or (@getData().modernizeJS is "off")
      @addCustomData "modernizeJS", "off"
    else
      @addCustomData "modernizeJS", "on"

    @addCustomData "resetsCSS", @getData().resetsCSS

    @addCustomData "codeHTML", Encoder.htmlEncode @HTMLace.getContents()
    @addCustomData "codeCSS", Encoder.htmlEncode @CSSace.getContents()
    @addCustomData "codeJS", Encoder.htmlEncode @JSace.getContents()

    @once "FormValidationPassed", =>
      setTimeout =>
        @reset()
      ,8000

    super

  reset:=>
    @submitBtn.setTitle "Post your Code Share"
    @removeCustomData "activity"

    @title.setValue ''
    @description.setValue ''

    @libHTMLClasses.setValue ''
    @libHTMLHeadExtras.setValue ''
    @libCSSExternal.setValue ''
    @libJSExternal.setValue ''

    @$("input[name=prefixCSSCheck]").prop "checked", false
    @$("input[name=modernizeJSCheck]").prop "checked", false

    @$(":radio[value=none]").prop "checked", true

    @$("select[name=modeHTML]").val("html").trigger "change"
    @$("select[name=modeCSS]").val("css").trigger "change"
    @$("select[name=modeJS]").val("javascript").trigger "change"

    @$("select[name=libsJS]").val("none").trigger "change"

    @utils.wait =>
      @HTMLace.setContents "//your HTML goes here..."
      @HTMLace.setSyntax 'html'
      @HTMLace.render()
      @CSSace.setContents "//your CSS goes here..."
      @CSSace.setSyntax 'css'
      @JSace.setContents "//your JavaScript goes here..."
      @JSace.setSyntax 'javascript'
      @codeShareResultView?.resetResultFrame()
      @codeShareResultView?.hide()
      @codeShareCloseButton?.hide()
      @codeShareResultButton?.setTitle "Run"
    @tagController.reset()
    @unsetWideScreen(undefined)

    @codeShareResultView.hide()
    @resultBanner.show()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit your Code Share"
    @addCustomData "activity", activity

    ## checkbox debug ## log "csw::switchToEditView (activity.prefixCSS):",activity.prefixCSS, "(activity.prefixCSSCheck):", activity.prefixCSSCheck

    {title, body, tags, prefixCSS, resetsCSS, classesHTML, extrasHTML, modeHTML, modeCSS, modeJS, libsJS, externalCSS, externalJS, modernizeJS} = activity

    HTMLcontent = activity.attachments[0]?.content
    CSScontent = activity.attachments[1]?.content
    JScontent = activity.attachments[2]?.content

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @title.setValue Encoder.htmlDecode title
      @description.setValue Encoder.htmlDecode body

      @HTMLace.setContents Encoder.htmlDecode HTMLcontent
      @CSSace.setContents Encoder.htmlDecode CSScontent
      @JSace.setContents Encoder.htmlDecode JScontent

      ## checkbox debug ##log "csw::sTEV::fillForm (prefixCSS):",prefixCSS

      if prefixCSS is "on"
        @$("input[name=prefixCSSCheck]").prop "checked", true
      else
        @$("input[name=prefixCSSCheck]").prop "checked", false

      # this removes the checkbox bug. (else you'd have it checked forever)
      @removeCustomData "prefixCSS"
      @removeCustomData "prefixCSSCheck"

      if modernizeJS is "on"
        @$("input[name=modernizeJSCheck]").prop "checked", true
      else
        @$("input[name=modernizeJSCheck]").prop "checked", false

      @removeCustomData "modernizeJS"
      @removeCustomData "modernizeJSCheck"

      @$(":radio[value=#{resetsCSS}]").prop "checked", true

      @$("select[name=modeHTML]").val(modeHTML).trigger "change"
      @$("select[name=modeCSS]").val(modeCSS).trigger "change"
      @$("select[name=modeJS]").val(modeJS).trigger "change"

      @$("select[name=libsJS]").val(libsJS).trigger "change"

      @$("input[name=classesHTML]").val(classesHTML)
      @$("input[name=extrasHTML]").val(extrasHTML)
      @$("input[name=externalCSS]").val(externalCSS)
      @$("input[name=externalJS]").val(externalJS)

    if @HTMLace?.editor? and @CSSace?.editor? and @JSace?.editor?
      fillForm()
    else
      @once "codeShare.aceLoaded", => fillForm()

    @codeShareResultView.hide()
    @resultBanner.show()


  switchToForkView:(activity)->
    @submitBtn.setTitle "Fork this Code Share"

    {title, body, tags, prefixCSS, resetsCSS, classesHTML, extrasHTML, modeHTML, modeCSS, modeJS, libsJS, externalCSS, externalJS, modernizeJS} = activity

    HTMLcontent = activity.attachments[0]?.content
    CSScontent = activity.attachments[1]?.content
    JScontent = activity.attachments[2]?.content

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @HTMLace.setContents Encoder.htmlDecode HTMLcontent
      @CSSace.setContents Encoder.htmlDecode CSScontent
      @JSace.setContents Encoder.htmlDecode JScontent

      if prefixCSS is "on"
        @$("input[name=prefixCSSCheck]").prop "checked", true
      else
        @$("input[name=prefixCSSCheck]").prop "checked", false

      @removeCustomData "prefixCSS"
      @removeCustomData "prefixCSSCheck"

      if modernizeJS is "on"
        @$("input[name=modernizeJSCheck]").prop "checked", true
      else
        @$("input[name=modernizeJSCheck]").prop "checked", false

      @removeCustomData "modernizeJS"
      @removeCustomData "modernizeJSCheck"

      @$(":radio[value=#{resetsCSS}]").prop "checked", true

      @$("select[name=modeHTML]").val(modeHTML).trigger "change"
      @$("select[name=modeCSS]").val(modeCSS).trigger "change"
      @$("select[name=modeJS]").val(modeJS).trigger "change"

      @$("select[name=libsJS]").val(libsJS).trigger "change"

      @$("input[name=classesHTML]").val(classesHTML)
      @$("input[name=extrasHTML]").val(Encoder.htmlDecode extrasHTML)
      @$("input[name=externalCSS]").val(externalCSS)
      @$("input[name=externalJS]").val(externalJS)

    if @HTMLace?.editor? and @CSSace?.editor? and @JSace?.editor?
      fillForm()
    else
      @once "codeShare.aceLoaded", =>
        fillForm()

    @codeShareResultView.hide()
    @resultBanner.show()

  widgetShown:->
    snippetCount = 0
    unless @HTMLace? and @CSSace? and @JSace?
      @loadAce()
    else
      @refreshEditorView()

  snippetCount = 0

  loadAce:->
    @HTMLloader.show()
    @CSSloader.show()
    @JSloader.show()

    @aceLoadCount = 0
    @aceLoaded = no

    @aceHTMLWrapper.addSubView @HTMLace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceCSSWrapper.addSubView @CSSace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceJSWrapper.addSubView @JSace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"

    # basically, count to three for every Ace firing its ready event

    @HTMLace.on "ace.ready",=>
      @aceLoadCount++
      @checkForAce()

    @CSSace.on "ace.ready",=>
      @aceLoadCount++
      @checkForAce()

    @JSace.on "ace.ready",=>
      @aceLoadCount++
      @checkForAce()

  checkForAce:=>
    @HTMLace.on "ace.ready", =>
      if @aceLoadCount is 3 then if not @aceLoaded
        @aceIsReady()
        @aceLoaded = yes
    @CSSace.on "ace.ready", =>
      if @aceLoadCount is 3 then if not @aceLoaded
        @aceIsReady()
        @aceLoaded = yes
    @JSace.on "ace.ready", =>
      if @aceLoadCount is 3 then if not @aceLoaded
        @aceIsReady()
        @aceLoaded = yes

  aceIsReady:=>
    @HTMLloader.destroy()
    @HTMLace.setShowGutter no
    @HTMLace.setContents "//your html goes here..."
    @HTMLace.setTheme()
    @HTMLace.setFontSize(12, no)
    @HTMLace.setSyntax "html"
    @HTMLace.editor.getSession().on 'change', => @refreshEditorView()

    @CSSloader.destroy()
    @CSSace.setShowGutter no
    @CSSace.setContents "//your css goes here..."
    @CSSace.setTheme()
    @CSSace.setFontSize(12, no)
    @CSSace.setSyntax "css"
    @CSSace.editor.getSession().on 'change', => @refreshEditorView()

    @JSloader.destroy()
    @JSace.setShowGutter no
    @JSace.setContents "//your javascript goes here..."
    @JSace.setTheme()
    @JSace.setFontSize(12, no)
    @JSace.setSyntax "javascript"
    @JSace.editor.getSession().on 'change', => @refreshEditorView()

    @emit "codeShare.aceLoaded"

  refreshEditorView:->
    # log "csw::refreshEditorView called"
    @HTMLace.editor.renderer.updateText()
    @CSSace.editor.renderer.updateText()
    @JSace.editor.renderer.updateText()

  setAceHeightByLines: (lineAmount) ->
    lineHeight  = @HTMLace.editor.renderer.lineHeight
    container   = @HTMLace.editor.container
    height      = lineAmount * lineHeight
    @$('.code-snip-holder').height height + 20
    @HTMLace.editor.resize()
    @CSSace.editor.resize()
    @JSace.editor.resize()

  viewAppended:()->
    @setClass "update-options codeshare"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder code-share">
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
        <div class="formline-codeshare">
        {{> @codeShareContainer}}
       </div>
        <div class="formline codeshare-buttons">
          {{> @codeShareResultButton}}
          {{> @codeShareCloseButton}}
          {{> @wideScreenBtn}}
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
