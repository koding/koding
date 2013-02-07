class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @loader = new KDLoaderView

    @readme = new KDView

    group.fetchReadme (err, readme)=>

      partial = \
        if err then err.message or "Access denied!"
        else        readme      or "No wiki found..."

      @readme.updatePartial partial
      @loader.hide()

  viewAppended:->

    super

    @loader.show()

  pistachio:->
    """
    {{> @loader}}
    {{> @readme}}
    """
