

class GroupsMembershipPolicyView extends KDView
  constructor:(options,data)->
    super options,data

    @setClass 'membership-policy'

    @loader           = new KDLoaderView
      cssClass        : 'loader'
    @loaderText       = new KDView
      partial         : 'Loading Membership Policy…'
      cssClass        : ' loader-text'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
    @loader.show()
    @loaderText.show()

    # {{> @tabView}}
  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    """
