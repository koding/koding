class ActivityChildViewTagGroup extends LinkGroup

  pistachio:->

    participants = @getData()
    {hasMore, totalCount, group} = @getOptions()

    @createMoreLink()

    switch totalCount
      when 0 then ""
      when 1 then "in {{> @participant0}}"
      when 2 then "in {{> @participant0}}{{> @participant1}}"
      when 3 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}"
      when 4 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}{{> @participant3}}"
      else "in {{> @participant0}}{{> @participant1}}{{> @participant2}}and {{> @more}}"
