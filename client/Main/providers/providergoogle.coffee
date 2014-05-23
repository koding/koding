class ProviderGoogle extends ProviderBaseView

  PROVIDER = "google"

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Google Compute Engine"
      description : """
        Run large-scale computing easily with Google's Compute Engine. Our
        Compute Engine is an IAAS that allows for scalable and efficient
        hosting configurations.
      """
