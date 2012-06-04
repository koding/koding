class ActivityDiscussionWidget extends KDFormView

  submit:(event)=>
    super event
    @reset()
    no

  reset:=>
    @inputDiscussionTitle.setValue ''
    @inputContent.setValue ''
    @addTags.input.clear()

  viewAppended:()->
    @setClass "update-options discussion clearfix"

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
      title : "Content:"
    labelAddTags = new KDLabelView
      title : "Add Tags:"
    
    @inputDiscussionTitle = new KDInputView
      name        : "title"
      placeholder : "Put a discussion title here..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Discussion title is required!"

    @inputContent = new KDInputView
      label       : labelContent
      name        : "body"
      type        : "textarea"
      placeholder : "Type what you wanna discuss here..."
      validate  :
        rules     : "required"
        messages  :
          required  : "discussion body is required!"
    
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
      title : "Start the Discussion"

    formline1.addSubView @inputDiscussionTitle
    formline2.addSubView labelContent
    formline2.addSubView @inputContent
    formline3.addSubView labelAddTags
    formline3.addSubView @addTags

    @addSubView formline1
    @addSubView formline2
    @addSubView formline3
    @addSubView submit
