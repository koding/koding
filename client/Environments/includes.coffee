module.exports = [

  "libs/js-yaml.min.js"

  "AppController.coffee"

  "views/environmentdataprovider.coffee"
  "views/scene/colortagselectorview.coffee"
  "views/scene/environmentcontainer.coffee"

  # Order is important ! ~ GG
  "views/scene/environmentrulecontainer.coffee"
  "views/scene/environmentdomaincontainer.coffee"
  "views/scene/environmentmachinecontainer.coffee"
  "views/scene/environmentextracontainer.coffee"
  ## ---

  "views/scene/environmentitemjointview.coffee"
  "views/scene/environmentitemsview.coffee"
  "views/scene/environmentruleitem.coffee"
  "views/scene/environmentextraitem.coffee"
  "views/scene/environmentdomainitem.coffee"
  "views/scene/environmentmachineitem.coffee"
  "views/scene/environmentsceneview.coffee"
  "views/scene/initializemachineview.coffee"
  "views/stackview.coffee"
  "views/resourcescontainer.coffee"
  "views/environmentsmainscene.coffee"
  "views/clonestackmodal.coffee"
  "views/createstackmodal.coffee"
  "views/stackprogressmodal.coffee"

  "views/domains/domaincreateform.coffee"
  "views/domains/commondomaincreateform.coffee"
  "views/domains/domaindeletionmodal.coffee"
  "views/domains/domainproductform.coffee"
  "views/domains/domainbuyform.coffee"
  "views/domains/domainbuyitem.coffee"
  "views/domains/domainpaymentconfirmform.coffee"
  "views/domains/subdomaincreateform.coffee"

  "views/vms/vmproductform.coffee"
  "views/vms/vmpaymentconfirmform.coffee"
  "views/vms/vmproductitemview.coffee"
  "views/vms/vmalwaysontogglebuttonview.coffee"

  # firewall
  "views/firewall/addfirewallrulemodal.coffee"
  "views/firewall/firewallfilterformview.coffee"

  "styl/app.environments.styl"
  "styl/app.envsettings.styl"

]
