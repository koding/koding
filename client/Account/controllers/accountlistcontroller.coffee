class AccountListViewController extends KDListViewController

  constructor: (options, data)->
    options.noItemFoundWidget = new KDView
      cssClass: "no-item-found hidden"
      partial : "<cite>#{options.noItemFoundText}</cite>"

    super options, data