class ActivityItemMenuItem extends JView

  pistachio: ->

    {title} = @getData()
    """
    <i class="#{KD.utils.slugify title} icon"></i>#{title}
    """
