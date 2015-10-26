# Multiple instances of the component on the page

If it's expected that there can be 2 or more instances of your component on the page,
it's possible that multiple instances use and change values from the same stores
they are binded to what can cause unexpected errors.

To avoid this problem, please follow the instructions below:
- Your component should have unique state id. It's automatically generated for you
if your component use ReactorMixin
- Stores which handle data for your component should save data in the immutable map
using state id as key. Thus, the map will contain as much keys as many components
on the page.
For example, you have a store for visibility flag and 2 components on the page. Each
component has unique state id. When visibility is changed for component 1, its value
is saved in the map with key = state id of component 1. And the same for component 2.
As result, we have a map with 2 key-value pairs: key 1 = state id of component 1,
value 1 = visibility flag for component 1; key 2 = state id of component 2, value 2 =
visibility flag for component 2
- Component state id is passed to the store in parameter(s) of action store is listening to.
So when you call an action from your component, you need to pass state id to the action
- Getters your component is binded to should also work with component's state id in order
to know value of what key they should return from correspondent store. That's why such
getters should be functions which accept state id as argument and use it as key
when returing value from store map.

Please find examples of this workflow in the stores, actions, getters and components of
ChatInputWidget.
