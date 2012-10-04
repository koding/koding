// --------------------------------------------------------------------------------------------------------------------
//
// iam-config.js - config for AWS Identity and Access Management
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required      = { required : true,  type : 'param'       };
var optional      = { required : false, type : 'param'       };
var requiredJson  = { required : true,  type : 'param-json'  };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    AddRoleToInstanceProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_AddRoleToInstanceProfile.html',
        defaults : {
            Action : 'AddRoleToInstanceProfile'
        },
        args : {
            Action              : required,
            InstanceProfileName : required,
            RoleName            : required,
        },
    },

    AddUserToGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_AddUserToGroup.html',
        defaults : {
            Action : 'AddUserToGroup'
        },
        args : {
            Action    : required,
            GroupName : required,
            UserName  : required,
        },
    },

    ChangePassword : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ChangePassword.html',
        defaults : {
            Action : 'ChangePassword'
        },
        args : {
            Action      : required,
            NewPassword : required,
            OldPassword : required,
        },
    },

    CreateAccessKey : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateAccessKey.html',
        defaults : {
            Action : 'CreateAccessKey'
        },
        args : {
            Action   : required,
            UserName : optional,
        },
    },

    CreateAccountAlias : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateAccountAlias.html',
        defaults : {
            Action : 'CreateAccountAlias'
        },
        args : {
            Action       : required,
            AccountAlias : required,
        },
    },

    CreateGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateGroup.html',
        defaults : {
            Action : 'CreateGroup'
        },
        args : {
            Action    : required,
            GroupName : required,
            Path      : optional,
        },
    },

    CreateInstanceProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateInstanceProfile.html',
        defaults : {
            Action : 'CreateInstanceProfile'
        },
        args : {
            Action              : required,
            InstanceProfileName : required,
            Path                : optional,
        },
    },

    CreateLoginProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateLoginProfile.html',
        defaults : {
            Action : 'CreateLoginProfile'
        },
        args : {
            Action   : required,
            Password : required,
            UserName : required,
        },
    },

    CreateRole : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateRole.html',
        defaults : {
            Action : 'CreateRole'
        },
        args : {
            Action                   : required,
            AssumeRolePolicyDocument : required,
            Path                     : optional,
            RoleName                 : required,
        },
    },

    CreateUser : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateUser.html',
        defaults : {
            Action : 'CreateUser'
        },
        args : {
            Action   : required,
            Path     : optional,
            UserName : required,
        },
    },

    CreateVirtualMFADevice : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateVirtualMFADevice.html',
        defaults : {
            Action : 'CreateVirtualMFADevice'
        },
        args : {
            Action               : required,
            Path                 : optional,
            VirtualMFADeviceName : required,
        },
    },

    DeactivateMFADevice : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeactivateMFADevice.html',
        defaults : {
            Action : 'DeactivateMFADevice'
        },
        args : {
            Action       : required,
            SerialNumber : required,
            UserName     : required,
        },
    },

    DeleteAccessKey : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteAccessKey.html',
        defaults : {
            Action : 'DeleteAccessKey'
        },
        args : {
            Action      : required,
            AccessKeyId : required,
            UserName    : optional,
        },
    },

    DeleteAccountAlias : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteAccountAlias.html',
        defaults : {
            Action : 'DeleteAccountAlias'
        },
        args : {
            Action       : required,
            AccountAlias : required,
        },
    },

    DeleteAccountPasswordPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteAccountPasswordPolicy.html',
        defaults : {
            Action : 'DeleteAccountPasswordPolicy'
        },
        args : {
            Action : required,
        },
    },

    DeleteGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteGroup.html',
        defaults : {
            Action : 'DeleteGroup'
        },
        args : {
            Action    : required,
            GroupName : required,
        },
    },

    DeleteGroupPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteGroupPolicy.html',
        defaults : {
            Action : 'DeleteGroupPolicy'
        },
        args : {
            Action     : required,
            GroupName  : required,
            PolicyName : required,
        },
    },

    DeleteInstanceProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteInstanceProfile.html',
        defaults : {
            Action : 'DeleteInstanceProfile'
        },
        args : {
            Action              : required,
            InstanceProfileName : required,
        },
    },

    DeleteLoginProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteLoginProfile.html',
        defaults : {
            Action : 'DeleteLoginProfile'
        },
        args : {
            Action   : required,
            UserName : required,
        },
    },

    DeleteRole : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteRole.html',
        defaults : {
            Action : 'DeleteRole'
        },
        args : {
            Action   : required,
            RoleName : required,
        },
    },

    DeleteRolePolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteRolePolicy.html',
        defaults : {
            Action : 'DeleteRolePolicy'
        },
        args : {
            Action     : required,
            PolicyName : required,
            RoleName   : required,
        },
    },

    DeleteServerCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteServerCertificate.html',
        defaults : {
            Action : 'DeleteServerCertificate'
        },
        args : {
            Action                : required,
            ServerCertificateName : required,
        },
    },

    DeleteSigningCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteSigningCertificate.html',
        defaults : {
            Action : 'DeleteSigningCertificate'
        },
        args : {
            Action        : required,
            CertificateId : required,
            UserName      : required,
        },
    },

    DeleteUser : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteUser.html',
        defaults : {
            Action : 'DeleteUser'
        },
        args : {
            Action   : required,
            UserName : required,
        },
    },

    DeleteUserPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteUserPolicy.html',
        defaults : {
            Action : 'DeleteUserPolicy'
        },
        args : {
            Action     : required,
            PolicyName : required,
            UserName   : required,
        },
    },

    DeleteVirtualMFADevice : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteVirtualMFADevice.html',
        defaults : {
            Action : 'DeleteVirtualMFADevice'
        },
        args : {
            Action       : required,
            SerialNumber : required,
        },
    },

    EnableMFADevice : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_EnableMFADevice.html',
        defaults : {
            Action : 'EnableMFADevice'
        },
        args : {
            Action              : required,
            AuthenticationCode1 : required,
            AuthenticationCode2 : required,
            SerialNumber        : required,
            UserName            : required,
        },
    },

    GetAccountPasswordPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetAccountPasswordPolicy.html',
        defaults : {
            Action : 'GetAccountPasswordPolicy'
        },
        args : {
            Action : required,
        },
    },

    GetAccountSummary : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetAccountSummary.html',
        defaults : {
            Action : 'GetAccountSummary'
        },
        args : {
            Action : required,
        },
    },

    GetGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetGroup.html',
        defaults : {
            Action : 'GetGroup'
        },
        args : {
            Action    : required,
            GroupName : required,
            Marker    : optional,
            MaxItems  : optional,
        },
    },

    GetGroupPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetGroupPolicy.html',
        defaults : {
            Action : 'GetGroupPolicy'
        },
        args : {
            Action     : required,
            GroupName  : required,
            PolicyName : required,
        },
    },

    GetInstanceProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetInstanceProfile.html',
        defaults : {
            Action : 'GetInstanceProfile'
        },
        args : {
            Action              : required,
            InstanceProfileName : required,
        },
    },

    GetLoginProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetLoginProfile.html',
        defaults : {
            Action : 'GetLoginProfile'
        },
        args : {
            Action   : required,
            UserName : required,
        },
    },

    GetRole : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetRole.html',
        defaults : {
            Action : 'GetRole'
        },
        args : {
            Action   : required,
            RoleName : required,
        },
    },

    GetRolePolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetRolePolicy.html',
        defaults : {
            Action : 'GetRolePolicy'
        },
        args : {
            Action     : required,
            PolicyName : required,
            RoleName   : required,
        },
    },

    GetServerCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetServerCertificate.html',
        defaults : {
            Action : 'GetServerCertificate'
        },
        args : {
            Action                : required,
            ServerCertificateName : required,
        },
    },

    GetUser : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetUser.html',
        defaults : {
            Action : 'GetUser'
        },
        args : {
            Action   : required,
            UserName : optional,
        },
    },

    GetUserPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetUserPolicy.html',
        defaults : {
            Action : 'GetUserPolicy'
        },
        args : {
            Action     : required,
            PolicyName : required,
            UserName   : required,
        },
    },

    ListAccessKeys : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListAccessKeys.html',
        defaults : {
            Action : 'ListAccessKeys'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            UserName : optional,
        },
    },

    ListAccountAliases : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListAccountAliases.html',
        defaults : {
            Action : 'ListAccountAliases'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
        },
    },

    ListGroupPolicies : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListGroupPolicies.html',
        defaults : {
            Action : 'ListGroupPolicies'
        },
        args : {
            Action    : required,
            GroupName : required,
            Marker    : optional,
            MaxItems  : optional,
        },
    },

    ListGroups : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListGroups.html',
        defaults : {
            Action : 'ListGroups'
        },
        args : {
            Action     : required,
            Marker     : optional,
            MaxItems   : optional,
            PathPrefix : optional,
        },
    },

    ListGroupsForUser : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListGroupsForUser.html',
        defaults : {
            Action : 'ListGroupsForUser'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            UserName : optional,
        },
    },

    ListInstanceProfiles : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListInstanceProfiles.html',
        defaults : {
            Action : 'ListInstanceProfiles'
        },
        args : {
            Action     : required,
            Marker     : optional,
            MaxItems   : optional,
            PathPrefix : optional,
        },
    },

    ListInstanceProfilesForRole : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListInstanceProfilesForRole.html',
        defaults : {
            Action : 'ListInstanceProfilesForRole'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            RoleName : required,
        },
    },

    ListMFADevices : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListMFADevices.html',
        defaults : {
            Action : 'ListMFADevices'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            UserName : optional,
        },
    },

    ListRolePolicies : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListRolePolicies.html',
        defaults : {
            Action : 'ListRolePolicies'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            RoleName : required,
        },
    },

    ListRoles : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListRoles.html',
        defaults : {
            Action : 'ListRoles'
        },
        args : {
            Action     : required,
            Marker     : optional,
            MaxItems   : optional,
            PathPrefix : optional,
        },
    },

    ListServerCertificates : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListServerCertificates.html',
        defaults : {
            Action : 'ListServerCertificates'
        },
        args : {
            Action     : required,
            Marker     : optional,
            MaxItems   : optional,
            PathPrefix : optional,
        },
    },

    ListSigningCertificates : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListSigningCertificates.html',
        defaults : {
            Action : 'ListSigningCertificates'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            UserName : optional,
        },
    },

    ListUserPolicies : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListUserPolicies.html',
        defaults : {
            Action : 'ListUserPolicies'
        },
        args : {
            Action   : required,
            Marker   : optional,
            MaxItems : optional,
            UserName : optional,
        },
    },

    ListUsers : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListUsers.html',
        defaults : {
            Action : 'ListUsers'
        },
        args : {
            Action     : required,
            Marker     : optional,
            MaxItems   : optional,
            PathPrefix : optional,
        },
    },

    ListVirtualMFADevices : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ListVirtualMFADevices.html',
        defaults : {
            Action : 'ListVirtualMFADevices'
        },
        args : {
            Action           : required,
            AssignmentStatus : optional,
            Marker           : optional,
            MaxItems         : optional,
        },
    },

    PutGroupPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_PutGroupPolicy.html',
        method : 'POST', // see note saying that policy documents can be large
        defaults : {
            Action : 'PutGroupPolicy'
        },
        args : {
            Action         : required,
            GroupName      : required,
            PolicyDocument : requiredJson,
            PolicyName     : required,
        },
    },

    PutRolePolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_PutRolePolicy.html',
        method : 'POST', // see note saying that policy documents can be large
        defaults : {
            Action : 'PutRolePolicy'
        },
        args : {
            Action         : required,
            PolicyDocument : requiredJson,
            PolicyName     : required,
            RoleName       : required,
        },
    },

    PutUserPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_PutUserPolicy.html',
        method : 'POST', // see note saying that policy documents can be large
        defaults : {
            Action : 'PutUserPolicy'
        },
        args : {
            Action         : required,
            PolicyDocument : requiredJson,
            PolicyName     : required,
            UserName       : required,
        },
    },

    RemoveRoleFromInstanceProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_RemoveRoleFromInstanceProfile.html',
        defaults : {
            Action : 'RemoveRoleFromInstanceProfile'
        },
        args : {
            Action              : required,
            InstanceProfileName : required,
            RoleName            : required,
        },
    },

    RemoveUserFromGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_RemoveUserFromGroup.html',
        defaults : {
            Action : 'RemoveUserFromGroup'
        },
        args : {
            Action    : required,
            GroupName : required,
            UserName  : required,
        },
    },

    ResyncMFADevice : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_ResyncMFADevice.html',
        defaults : {
            Action : 'ResyncMFADevice'
        },
        args : {
            Action              : required,
            AuthenticationCode1 : required,
            AuthenticationCode2 : required,
            SerialNumber        : required,
            UserName            : required,
        },
    },

    UpdateAccessKey : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateAccessKey.html',
        defaults : {
            Action : 'UpdateAccessKey'
        },
        args : {
            Action      : required,
            AccessKeyId : required,
            Status      : required,
            UserName    : optional,
        },
    },

    UpdateAccountPasswordPolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateAccountPasswordPolicy.html',
        defaults : {
            Action : 'UpdateAccountPasswordPolicy'
        },
        args : {
            Action                     : required,
            AllowUsersToChangePassword : optional,
            MinimumPasswordLength      : optional,
            RequireLowercaseCharacters : optional,
            RequireNumbers             : optional,
            RequireSymbols             : optional,
            RequireUppercaseCharacters : optional,
        },
    },

    UpdateAssumeRolePolicy : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateAssumeRolePolicy.html',
        defaults : {
            Action : 'UpdateAssumeRolePolicy'
        },
        args : {
            Action         : required,
            PolicyDocument : required,
            RoleName       : required,
        },
    },

    UpdateGroup : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateGroup.html',
        defaults : {
            Action : 'UpdateGroup'
        },
        args : {
            Action       : required,
            GroupName    : required,
            NewGroupName : optional,
            NewPath      : optional,
        },
    },

    UpdateLoginProfile : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateLoginProfile.html',
        defaults : {
            Action : 'UpdateLoginProfile'
        },
        args : {
            Action   : required,
            Password : required,
            UserName : required,
        },
    },

    UpdateServerCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateServerCertificate.html',
        defaults : {
            Action : 'UpdateServerCertificate'
        },
        args : {
            Action                   : required,
            NewPath                  : optional,
            NewServerCertificateName : optional,
            ServerCertificateName    : required,
        },
    },

    UpdateSigningCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateSigningCertificate.html',
        defaults : {
            Action : 'UpdateSigningCertificate'
        },
        args : {
            Action        : required,
            CertificateId : required,
            Status        : required,
            UserName      : required,
        },
    },

    UpdateUser : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UpdateUser.html',
        defaults : {
            Action : 'UpdateUser'
        },
        args : {
            Action      : required,
            NewPath     : optional,
            NewUserName : optional,
            UserName    : required,
        },
    },

    UploadServerCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UploadServerCertificate.html',
        defaults : {
            Action : 'UploadServerCertificate'
        },
        args : {
            Action                : required,
            CertificateBody       : required,
            CertificateChain      : optional,
            Path                  : optional,
            PrivateKey            : required,
            ServerCertificateName : required,
        },
    },

    UploadSigningCertificate : {
        url : 'http://docs.amazonwebservices.com/IAM/latest/APIReference/API_UploadSigningCertificate.html',
        defaults : {
            Action : 'UploadSigningCertificate'
        },
        args : {
            Action          : required,
            CertificateBody : required,
            UserName        : optional,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
