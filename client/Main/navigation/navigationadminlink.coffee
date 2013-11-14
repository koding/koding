class AdminNavigationLink extends NavigationLink

  click:(event)->
    cb = @getData().callback
    cb.call @ if cb
