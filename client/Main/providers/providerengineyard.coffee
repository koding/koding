class ProviderEngineyard extends ProviderBaseView

  PROVIDER = "engineyard"

  constructor:->
    super
      cssClass    : PROVIDER
      providerId    : PROVIDER
    ,
      name        : "EngineYard"
      description : """
        Spend less time worrying about operational tasks and
        more time focusing on your app.
      """

    @createFormView()