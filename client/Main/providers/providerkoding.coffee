class ProviderKoding extends ProviderBaseView

  PROVIDER = "koding"

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Koding"
      description : """
        Koding provides you a full featured vms which bundles all popular Web
        technologies, ready to use.
      """
