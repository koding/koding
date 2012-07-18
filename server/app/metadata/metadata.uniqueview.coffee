class Metadata.UniqueView
  
  Metadata.defineFlags @,
    new Flag options: [
      t 'user view'
      t 'guest view'
    ]
  
  @outputFilters =
    
    # groupFilter: _.identity
    groupFilter: (elements, accountId)->
      viewsCount = 0
      for element in elements
        if element.type is 'UniqueView'
          viewsCount += element.results.userViewsCount
      
      {viewsCount}
        
  
    elementFilter: (rawMetadata, account)->
      userViewsCount = 0
      if flag = rawMetadata.get 'flags.0'
        userViewsCount  = flag.results?['user view' ]?.length or 0
        
      bam = {
        type:  rawMetadata.type
        replyId: rawMetadata.replyId
        results: {
          userViewsCount
        }
      }

      bam
      
      
# the old one metadata
# class Metadata.UniqueView
# 
#   Metadata.defineFlags @,
#     new Flag options: [
#       t 'user view'
#       t 'guest view'
#     ]
# 
#   @forceOption =(rawMetadata, account)->
#     if account.isGuest
#       'guest view'
#     else
#       'user view'
# 
#   @outputFilters =
# 
#     # groupFilter: _.identity
#     groupFilter: (elements, accountId)->
#       viewCount = 0
#       for element in elements
#         if flag = element.get 'flags.0'
#           views = flag.results['user view']
#           myId = accountId
#           try
#             isMyView = myId.equals.bind(myId)
#             viewCount++ unless _(views).detect isMyVote
#           catch e
#       {viewCount}
# 
#     elementFilter: (rawMetadata, account)->
# 
#       for flag in rawMetadata.flags when flag.type is 'UniqueView'
#         guestViewsCount = flag.results['guest view'].length
#         userViewsCount  = flag.results['user view' ].length
# 
#       {
#         type:  rawMetadata.type
#         flags: {
#           guestViewsCount
#           userViewsCount
#         }
#       }