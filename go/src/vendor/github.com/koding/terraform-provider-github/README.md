[![wercker status]
(https://app.wercker.com/status/f65e85e8245114e76a436f6c22cfcdf2/m "wercker status")](https://app.wercker.com/project/bykey/f65e85e8245114e76a436f6c22cfcdf2)

# terraform-provider-github
Github Provider for Terraform


This plugin for github provides the teams following features;
 - Adding the user into the organization
 - Forking the repos of the organization
 - Adding SSH Key of the user into the user account


Terraform basicly satisfy 4 function as; create, delete, read and update..


# Usage

Following fields should be filled to use github plugin.

- Organization Key: should be given by owner of the organization
- User Key : User key is the auth. token for user 
- username: name of the github user 
- organization : name of the organization that user will join
- repos : repos that will be forked
- teams : teams are the teams of the organization that user will join
- title : title of the SSH Key
- SSH Key : requires to add the key into the user's account 


```
# Specify the provider and access details
provider "github" {
    #Token for organization of owner  
    organizationKey = "2ce581a7ba0033aafabad3843d2b1230739"
    #Token for the authecticated user
    userKey = "6a3f32ebb5bb0262f19b78edd4935ce581a7b"
}

resource "github" "repo" {
  username = "mehmetalisavas"
  organization = "organizationName"
  repos = ["repo", "repo2"]
  teams = ["teams", "teams2"]
  title = "SSH Key Title"
  SSHKey = "ssh-rsa 
  AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q"
}
```
For more information about terraform : https://github.com/hashicorp/terraform
