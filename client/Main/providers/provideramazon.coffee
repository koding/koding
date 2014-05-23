class ProviderAmazon extends ProviderBaseView

  PROVIDER = 'amazon'

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Amazon"
      description : """
        Amazon Web Services offers reliable, scalable, and inexpensive
        cloud computing services. Free to join, pay only for what you use.
      """
