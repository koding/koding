class DeveloperPlan extends PricingPacksView

  subscriptionTag: "vm"

  packs: [
    title        : "1x"
    tag          : "rp1"
    cssClass     : "blue"
    packFeatures :
      "CPU"      : "2x"
      "RAM"      : "2GB"
      "DISK"     : "10GB"
      "VMs"      : "10x"
      "Always On": "1x"
    price        : "$19"
  ,
    title        : "2x"
    tag          : "rp2"
    cssClass     : "green"
    packFeatures :
      "CPU"      : "4x"
      "RAM"      : "4GB"
      "DISK"     : "20GB"
      "VMs"      : "20x"
      "Always On": "2x"
    price        : "$39"
  ,
    title        : "3x"
    tag          : "rp3"
    cssClass     : "yellow"
    packFeatures :
      "CPU"      : "6x"
      "RAM"      : "6GB"
      "DISK"     : "30GB"
      "VMs"      : "30x"
      "Always On": "3x"
    price        : "$59"
  ,
    title        : "4x"
    tag          : "rp4"
    cssClass     : "orange"
    packFeatures :
      "CPU"      : "8x"
      "RAM"      : "8GB"
      "DISK"     : "40GB"
      "VM"       : "40x"
      "Always On": "4x"
    price        : "$79"
  ,
    title        : "5x"
    tag          : "rp5"
    cssClass     : "red"
    packFeatures :
      "CPU"      : "10x"
      "RAM"      : "10GB"
      "DISK"     : "50GB"
      "VMs"      : "50x"
      "Always On": "5x"
    price        : "$99"
  ]
