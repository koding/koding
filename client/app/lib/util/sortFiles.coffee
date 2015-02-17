module.exports = (a, b) ->

  { name: na } = a
  { name: nb } = b

  la = na.toLowerCase()
  lb = nb.toLowerCase()

  switch
    when la is lb
      switch
        when na is nb  then 0
        when na > nb   then 1
        when na < nb   then -1
    when la > lb       then 1
    when la < lb       then -1
