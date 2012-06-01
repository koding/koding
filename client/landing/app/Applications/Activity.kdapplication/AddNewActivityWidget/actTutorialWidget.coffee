class ActivityTutorialWidget extends KDFormView

  submit:(event)=>
    super event
    @reset()
    no

  reset:=>
    @inputTutorialTitle.inputSetValue ''
    @inputContent.inputSetValue ''
    @addTags.input.clear()
    
  viewAppended:()->
    @setClass "update-options tutorial clearfix"

    formline1 = new KDCustomHTMLView 
      tagName : "div" 
      cssClass : "clearfix form-headline input-with-extras"
    formline2 = new KDCustomHTMLView 
      tagName : "div" 
      cssClass : "clearfix formline"
    formline3 = new KDCustomHTMLView 
      tagName : "div" 
      cssClass : "clearfix formline"
      
    labelContent = new KDLabelView
      title : "Tutorial:"
    labelAddTags = new KDLabelView
      title : "Add Tags:"

    @inputTutorialTitle = new KDInputView
      name        : "tutorial-title"
      placeholder : "Tutorial title..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Tutorial title is required!"

    @inputContent = new KDInputView
      label       : labelContent
      type        : "textarea"
      name        : "Tutorial-content"
      placeholder : "tutorial content..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Tutorial can't be left empty!"
      

    @addTags = new CommonView_AddTagView
      input:
        placeholder : "Add some tags"
        name: 'tags'
        itemClass : MemberAutoCompleteItemView
      button    :
        title     : ""
        icon      : yes 
        iconClass : "plus"

    submit = new KDButtonView
      style : "clean-gray"
      title : "Share your Tutorial"

    formline1.addSubView @inputTutorialTitle
    formline2.addSubView labelContent
    formline2.addSubView @inputContent
    formline3.addSubView labelAddTags
    formline3.addSubView @addTags

    @addSubView formline1
    @addSubView formline2
    @addSubView formline3
    @addSubView submit
