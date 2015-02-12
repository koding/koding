class ProviderDigitalOcean extends ProviderBaseView

  PROVIDER = "digitalocean"

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "DigitalOcean"
      description : """
        Deploy an 512MB RAM and 20GB SSD cloud server in 55
        seconds for $5/month. Simple, fast, scalable SSD cloud virtual servers.
      """
