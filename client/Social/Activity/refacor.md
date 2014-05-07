# Refactor notes

- broke Bugs app, needs to be fixed or removed
- removed ReferalBox
- removed Ticker
- removed widget stuff

```
# @topWidgetWrapper  = new KDCustomHTMLView
# @leftWidgetWrapper = new KDCustomHTMLView
# widgetController.showWidgets [
#   { view: @topWidgetWrapper,  key: 'ActivityTop'  }
#   { view: @leftWidgetWrapper, key: 'ActivityLeft' }
# ]
# @sidebar.once 'viewAppended', =>
#   @sidebar.addSubView @leftWidgetWrapper
# @sidebar.once 'viewAppended', =>
#   @sidebar.addSubView @leftWidgetWrapper
```

- removed side items all together

```
@groupListBox      = new UserGroupList
@topicsBox         = new ActiveTopics
@usersBox          = new ActiveUsers

# TODO : if not on private group DO NOT create those ~EA
# group components
@groupDescription = new GroupDescription
@groupMembers     = new GroupMembers
```