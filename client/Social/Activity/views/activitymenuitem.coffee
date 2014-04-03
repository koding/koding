class ActivityItemMenuItem extends JView

  pistachio: ->

    {title} = @getData()
    slugifiedTitle = KD.utils.slugify title
    """
    <i class="#{slugifiedTitle} icon"></i>#{title}
    """
