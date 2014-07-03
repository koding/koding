import pyrax

pyrax.set_setting('identity_type', 'rackspace')
pyrax.set_setting("region", "IAD")

pyrax.set_credentials("kodinginc", "96d6388ccb936f047fd35eb29c36df17")


# Using direct method

# cls = pyrax.utils.import_class('pyrax.identity.rax_identity.RaxIdentity')
# pyrax.identity = cls()

# 

# # Using credentials file
# pyrax.set_credential_file("./rax_creds_file")

# # Using keychain
# pyrax.keyring_auth("my_username")
# # Using keychain with username set in configuration file
# pyrax.keyring_auth()