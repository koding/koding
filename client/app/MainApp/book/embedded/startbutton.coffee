class StartTutorialButton extends JView

  constructor:(options={},data )->
    super options, data
    @button = new KDButtonView
      title      : "Start tutorial"
      cssClass   : "cta_button full_width"
      callback   : =>
        welcomePageIndex = 10
        @getDelegate().fillPage welcomePageIndex
        
  pistachio:->
    """
    {{> @button}}
    """
