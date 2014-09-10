class TeamPlan extends PricingPacksView

  subscriptionTag: "custom-plan"

  packs: [
    title        : "10x"
    tag          : "tp10"
    cssClass     : "blue"
    packFeatures :
      "CPU"      : "20x"
      "RAM"      : "20GB"
      "DISK"     : "100GB"
      "VMs"      : "100x"
      "Always On": "10x"
    price        : "$299"
  ,
    title        : "25x"
    tag          : "tp25"
    cssClass     : "green"
    packFeatures :
      "CPU"      : "50x"
      "RAM"      : "50GB"
      "DISK"     : "250GB"
      "VMs"      : "250x"
      "Always On": "25x"
    price        : "$749"
  ,
    title        : "50x"
    tag          : "tp50"
    cssClass     : "yellow"
    packFeatures :
      "CPU"      : "100x"
      "RAM"      : "100GB"
      "DISK"     : "500GB"
      "VMs"      : "500x"
      "Always On": "50x"
    price        : "$1499"
  ,
    title        : "75x"
    tag          : "tp75"
    cssClass     : "orange"
    packFeatures :
      "CPU"      : "150x"
      "RAM"      : "150GB"
      "DISK"     : "750GB"
      "VM"       : "750x"
      "Always On": "75x"
    price        : "$2249"
  ]
