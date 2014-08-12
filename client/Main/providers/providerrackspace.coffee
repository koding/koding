class ProviderRackspace extends ProviderBaseView

  PROVIDER = "rackspace"

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Rackspace"
      description : """
        Sure, rock-solid infrastructure is important (and we’re right there
        with 99.999% uptime). But service and expertise are just as critical.
        That’s why we include a team of Cloud Engineers with every account—we
        know your success depends on it.
      """
