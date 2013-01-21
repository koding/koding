class AppScreenshotsListItem extends KDListItemView

  partial :(data)-> "<figure><img class='screenshot' src='/images/uploads/#{data.screenshot}'></figure>"
