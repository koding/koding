class NFinderItemDeleteView extends JView

  constructor:->

    super
    @setClass "delete-container"
    @button = new KDButtonView
      title     : 'Delete'
      style     : 'clean-red'
      callback  : =>
        @propagateEvent KDEventType : "FinderDeleteConfirmation", yes

    @cancel = new KDCustomHTMLView
      tagName   : 'a'
      attributes:
        href    : '#'
        title   : 'Cancel'
      cssClass  : 'cancel'
      click     : =>
        @propagateEvent KDEventType : "FinderDeleteConfirmation", no
    
    @label = new KDLabelView
      title     : 'Are you sure?'
  
  show:->
    
    super
    @button.focus()

  pistachio:->
    
    """
    {{> @label}}
    {{> @button}}  
    {{> @cancel}}
    """

  keyDown:(event)->

    switch event.which
      when 27 #esc
        @propagateEvent KDEventType : "FinderDeleteConfirmation", no
        no
      when 9
        unless @button.$().is(":focus")
          @button.$().focus()
          no
