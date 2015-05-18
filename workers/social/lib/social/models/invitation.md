## Invitations

### Listing

status constant can be `accepted`

`selector = { status: "pending" }`

pagination can be utilized with skip and limit

default values
    * skip  : 0
    * limit : 25
    * sort  : createdAt : -1

`options  = { skip: 4, limit: 43, sort: createdAt: -1}`

`_kd.remote.api.JInvitation.some(selector, options, callback)`

### Searching

* query = { query: "cihangir", status: "accepted "} # query searches in email or firstname

* options = {} # options are same with JInvitation.some function

`_kd.remote.api.JInvitation.search(query, options, callback)`

### Revoke invitation

All JInvitation instances have a function with following signature `instance.remove(callback)`, one can remove invitation with that

### Resend Invitation

All JInvitation instances have `code` property, one can call sendInvitationByCode with code
    `_kd.remote.api.JInvitation.sendInvitationByCode("7445aa508a1b8deaa97a13ce8ad00b4f9148d6e4", callback)`
to re-send that email again

### Creating & Sending

```
data = {
    invitations:[
        {email:"cihangir@koding.com", firstName:"cihangir", lastName:"savas"}
    ]
}
```

firstName and lastName are optional, invitation email will be sent automatically

`_kd.remote.api.JInvitation.create(data, callback)`
