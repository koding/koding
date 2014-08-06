class AccountListViewController extends KDListViewController

  constructor: (options, data)->

    options.noItemFoundWidget = new KDView
      cssClass: "no-item-found hidden"
      partial : "<cite>#{options.noItemFoundText}</cite>"

    options.lazyLoaderOptions =
      spinnerOptions          :
        loaderOptions         :
          shape               : 'spiral'
          color               : '#a4a4a4'
        size                  :
          width               : 40
          height              : 40

    super options, data
