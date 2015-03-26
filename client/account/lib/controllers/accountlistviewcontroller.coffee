kd = require 'kd'
KDListViewController = kd.ListViewController
KDView = kd.View
module.exports = class AccountListViewController extends KDListViewController

  constructor: (options, data)->

    options.noItemFoundWidget = new KDView
      cssClass: "no-item-found"
      partial : "<cite>#{options.noItemFoundText}</cite>"

    options.lazyLoaderOptions =
      spinnerOptions          :
        cssClass              : 'AppModal--account-tabSpinner'
        loaderOptions         :
          shape               : 'spiral'
          color               : '#a4a4a4'
        size                  :
          width               : 40
          height              : 40

    super options, data


