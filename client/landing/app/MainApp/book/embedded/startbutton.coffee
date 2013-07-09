class StartTutorialButton extends JView

  constructor:(options={},data )->
    super options, data
    @button = new KDButtonView
      title      : "Start tutorial"
      cssClass   : "cta_button full_width"
      callback   : =>
        @getDelegate().fillPage 2
        
    

  pistachio:->
    """
    {{> @button}}
    """
