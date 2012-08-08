class ActivityChildViewTagGroup extends LinkGroup

  pistachio:->

    participants = @getData()
    {hasMore, totalCount, group} = @getOptions()

    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        new FollowedModalView {group}, @getData()

    switch totalCount
      when 0 then ""
      when 1 then "in {{> @participant0}}"
      when 2 then "in {{> @participant0}}{{> @participant1}}"
      when 3 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}"
      when 4 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}{{> @participant3}}"
      else "in {{> @participant0}}{{> @participant1}}{{> @participant2}}and {{> @more}}"
