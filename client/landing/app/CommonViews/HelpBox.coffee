class HelpBox extends JView

  constructor:(options = {}, data = {})->

    options.cssClass or= "help-box"
    options.title    or= "NEED HELP?"
    options.subtitle or= "Learn about sharing"

    data.title    = options.title
    data.subtitle = options.subtitle

    super options, data

  pistachio:()->

    """
      <span></span>
      <div>
        {cite{ #(title)}}
        <a href="#">{{ #(subtitle)}}</a>
      </div>
    """
