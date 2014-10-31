# overrride ::setAttribute to not put
# testpath attributes in production - SY
do ->

  {environment} = KD.config

  return  if environment isnt 'production' and KD.isTesting

  setAttribute = KDView::setAttribute

  KDView::setAttribute = (attr, val) ->
    return  if attr is 'testpath'
    setAttribute.call this, attr, val

