class ActivityQuestionWidget extends KDFormView

  submit:->
    super
    KD.track "Activity", "QuestionSubmitted"
    @reset()
    no

  reset:->
    @inputQuestionTitle.setValue ''
    @inputContent.setValue ''
    @addTags.input.clear()

  viewAppended:->
    @setClass "update-options question clearfix"

    formline1 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "clearfix form-headline input-with-extras"
    formline2 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "clearfix formline"
    formline3 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "clearfix formline"

    # labelQuestionTitle = new KDLabelView
    #   title : "Question:"
    labelContent = new KDLabelView
      title : "Content:"
    labelAddTags = new KDLabelView
      title : "Add Tags:"

    @inputQuestionTitle = new KDInputView
      name        : "questionTitle"
      placeholder : "Question title..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Question title is required!"


    @inputContent = new KDInputView
      label       : labelContent
      type        : "textarea"
      name        : "questionContent"
      placeholder : "Question body..."
      validate  :
        rules     : "required"
        messages  :
          required  : "Question body is required!"

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
      title : "Ask your Question"
      # callback : @bound "submit"

    # formline1.addSubView labelQuestionTitle
    formline1.addSubView @inputQuestionTitle
    formline2.addSubView labelContent
    formline2.addSubView @inputContent
    formline3.addSubView labelAddTags
    formline3.addSubView @addTags
    # formline3.addSubView tagFilter = new TagFilter

    @addSubView formline1
    @addSubView formline2
    @addSubView formline3
    @addSubView submit
