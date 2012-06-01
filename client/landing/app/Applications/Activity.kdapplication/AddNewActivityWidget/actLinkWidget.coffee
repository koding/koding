class ActivityLinkWidget extends KDFormView

  submit:(event)=>
    super event
    @reset()
    no

  reset:=>
    @inputLinkTitle.inputSetValue ''
    @inputLink.inputSetValue ''
    @addTags.input.clear()
    
  viewAppended:()->
    # @setPartial @partial
    @setClass "update-options sharelink clearfix"

    formline1 = new KDCustomHTMLView
      tagName : "div" 
      cssClass : "clearfix form-headline input-with-extras"
    
    formActionsMask = new KDCustomHTMLView
      tagName : "div"
      cssClass : "form-actions-mask"

    formActionsHolder = new KDCustomHTMLView
      tagName : "div"
      cssClass : "form-actions-holder"

    formline2 = new KDCustomHTMLView 
      tagName : "div" 
      cssClass : "clearfix formline link-body"

    # => commented out for private beta
    # formline3 = new KDCustomHTMLView 
    #   tagName : "div" 
    #   cssClass : "clearfix formline"
    
    formline4 = new KDCustomHTMLView 
      tagName : "div" 
      cssClass : "clearfix formline submit"
    
    buttonsHolder = new KDCustomHTMLView 
      tagName : "div"
      cssClass : "clearfix formline buttonsHolder"

    formActionsHolder.addSubView formline2
    # formActionsHolder.addSubView formline3
    formActionsHolder.addSubView formline4
      
    labelLink = new KDLabelView
      title : "Link:"
    labelAddTags = new KDLabelView
      title : "Add Tags:"
    
    @inputLinkTitle = new KDInputView
      name        : "link"
      placeholder : "Give a title to your link..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Link title is required!"

    @inputLink = new KDInputView
      label       : labelLink
      name        : "body"
      placeholder : "Enter your link..."
      validate  :
        rules     : "required"
        messages  :
          required  : "link is required!"
    
    # => commented out for private beta
    # @addTags = new CommonView_AddTagView
    #   input:
    #     placeholder : "Add some tags"
    #     name: 'tags'
    #     itemClass : MemberAutoCompleteItemView
    #   button    :
    #     title     : ""
    #     icon      : yes 
    #     iconClass : "plus"
    
    submitBox = new KDCustomHTMLView
      tagName : "div"
      cssClass : "submit-box"

    cancelLink = new KDCustomHTMLView
      tagName : "a"
      partial : "Cancel"

    submit = new KDButtonView
      style : "clean-gray"
      title : "Share your Link"

    formline1.addSubView @inputLinkTitle
    
    formline2.addSubView labelLink
    formline2.addSubView @inputLink
    
    # => commented out for private beta
    # formline3.addSubView labelAddTags
    # formline3.addSubView @addTags

    formline4.addSubView buttonsHolder
    buttonsHolder.addSubView helpBox = new HelpBox
    buttonsHolder.addSubView submitBox
    submitBox.addSubView cancelLink
    submitBox.addSubView submit

    @addSubView formline1
    @addSubView formActionsMask
    formActionsMask.addSubView formActionsHolder






























