class JView extends KDView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  pistachio:-> ""
