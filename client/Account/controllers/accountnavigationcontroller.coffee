class AccountNavigationController extends KDListViewController

  loadView:(mainView)->

    mainView.setPartial "<h3>#{@getData().title}</h3>"
    super
