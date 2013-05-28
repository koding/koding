class VMMainView extends JView

  constructor:(options={}, data)->

    options.cssClass or= "vms"
    data or= {}
    super options, data

  pistachio:->
    """
      VMs
    """
