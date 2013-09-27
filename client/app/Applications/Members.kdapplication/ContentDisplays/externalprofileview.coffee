class ExternalProfileView extends JView

  constructor: (options, account) ->

    options.type   or= 'no type given'
    options.cssClass = KD.utils.curry "external-profile #{options.type}", options.cssClass

    super options, account

    appManager = KD.getSingleton 'appManager'
    # appManager.tell 'Account', 'fetchProviders', (providers)->

  viewAppended:->
    super
    # @setPartial @getOption 'type'

  pistachio:->

    """
    <span class="icon"></span>
    """