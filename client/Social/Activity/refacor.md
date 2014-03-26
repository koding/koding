# Refactor notes

- removed ReferalBox
- removed Ticker

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