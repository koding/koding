class ActivityItemMenuItem extends JView

  pistachio: ->

    {title} = @getData()
    """
    #{title}
    """
