// --------------------------------------------------------------------------------------------------------------------
//
// elb-config.js - config for AWS Elastic Load Balancing
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    ApplySecurityGroupsToLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_ApplySecurityGroupsToLoadBalancer.html',
        defaults : {
            Action : 'ApplySecurityGroupsToLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            SecurityGroups : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    AttachLoadBalancerToSubnets : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_AttachLoadBalancerToSubnets.html',
        defaults : {
            Action : 'AttachLoadBalancerToSubnets'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            Subnets : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    ConfigureHealthCheck : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_ConfigureHealthCheck.html',
        defaults : {
            Action : 'ConfigureHealthCheck'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            HealthyThreshold : {
                name     : 'Healthcheck.HealthyThreshold',
                required : true,
                type     : 'param',
            },
            Interval : {
                name     : 'Healthcheck.Interval',
                required : true,
                type     : 'param',
            },
            Target : {
                name     : 'Healthcheck.Target',
                required : true,
                type     : 'param',
            },
            Timeout : {
                name     : 'Healthcheck.Timeout',
                required : true,
                type     : 'param',
            },
            UnhealthyThreshold : {
                name     : 'Healthcheck.UnhealthyThreshold',
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateAppCookieStickinessPolicy : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_CreateAppCookieStickinessPolicy.html',
        defaults : {
            Action : 'CreateAppCookieStickinessPolicy'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CookieName : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            PolicyName : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateLBCookieStickinessPolicy : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_CreateLBCookieStickinessPolicy.html',
        defaults : {
            Action : 'CreateLBCookieStickinessPolicy'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            CookieExpirationPeriod : {
                required : false,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            PolicyName : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_CreateLoadBalancer.html',
        defaults : {
            Action : 'CreateLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            AvailabilityZones : {
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
            Listeners : {
                required : true,
                type     : 'param-array-of-objects',
                setName  : 'Listeners.member',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            SecurityGroups : {
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
            Subnets : {
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    CreateLoadBalancerListeners : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_CreateLoadBalancerListeners.html',
        defaults : {
            Action : 'CreateLoadBalancerListeners'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Listeners : {
                required : true,
                type     : 'param-array-of-objects',
                setName  : 'Listeners.member',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
        },
    },

    CreateLoadBalancerPolicy : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_CreateLoadBalancerPolicy.html',
        defaults : {
            Action : 'CreateLoadBalancerPolicy'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            Listeners : {
                // creates Listeners.member.1, Listeners.member.2, ...etc...
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            PolicyAttributes : {
                // wanted: AttributeName and AttributeValue for each object
                required : false,
                type     : 'param-array-of-objects',
                setName  : 'PolicyAttributes.member',
            },
            PolicyName : {
                required : true,
                type     : 'param',
            },
            PolicyTypeName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DeleteLoadBalancer.html',
        defaults : {
            Action : 'DeleteLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeleteLoadBalancerListeners : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DeleteLoadBalancerListeners.html',
        defaults : {
            Action : 'DeleteLoadBalancerListeners'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            LoadBalancerPorts : {
                required : true,
                type     : 'param-set',
                prefix   : 'member',
            },
        },
    },

    DeleteLoadBalancerPolicy : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DeleteLoadBalancerPolicy.html',
        defaults : {
            Action : 'DeleteLoadBalancerPolicy'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            PolicyName : {
                required : true,
                type     : 'param',
            },
        },
    },

    DeregisterInstancesFromLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DeregisterInstancesFromLoadBalancer.html',
        defaults : {
            Action : 'DeregisterInstancesFromLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            // do an array-set instead of an array-of-objects (since it only has one item)
            Instances : {
                name     : 'InstanceId',
                required : true,
                type     : 'param-array-set',
                setName  : 'Instances.member',
            },
        },
    },

    DescribeInstanceHealth : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DescribeInstanceHealth.html',
        defaults : {
            Action : 'DescribeInstanceHealth'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            // do an array-set instead of an array-of-objects (since it only has one item)
            Instances : {
                name     : 'InstanceId',
                required : false,
                type     : 'param-array-set',
                setName  : 'Instances.member',
            },
        },
    },

    DescribeLoadBalancerPolicies : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DescribeLoadBalancerPolicies.html',
        defaults : {
            Action : 'DescribeLoadBalancerPolicies'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : false,
                type     : 'param',
            },
            PolicyNames : {
                required : false,
                type     : 'param-array',
                prefix   : 'member'
            },
        },
    },

    DescribeLoadBalancerPolicyTypes : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DescribeLoadBalancerPolicyTypes.html',
        defaults : {
            Action : 'DescribeLoadBalancerPolicyTypes'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            PolicyTypeNames : {
                required : false,
                type     : 'param-array',
                prefix   : 'member'
            },
        },
    },

    DescribeLoadBalancers : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DescribeLoadBalancers.html',
        defaults : {
            Action : 'DescribeLoadBalancers'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerNames : {
                // LoadBalancerNames.member.1, LoadBalancerNames.member.2, ...etc...
                required : false,
                type     : 'param-array',
                prefix   : 'member',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
        },
    },

    DetachLoadBalancersFromSubnets : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DetachLoadBalancerFromSubnets.html',
        defaults : {
            Action : 'DetachLoadBalancersFromSubnets'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            Subnets : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    DisableAvailabilityZonesForLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_DisableAvailabilityZonesForLoadBalancer.html',
        defaults : {
            Action : 'DisableAvailabilityZonesForLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            AvailabilityZones : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    EnableAvailabilityZonesForLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_EnableAvailabilityZonesForLoadBalancer.html',
        defaults : {
            Action : 'EnableAvailabilityZonesForLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            AvailabilityZones : {
                required : true,
                type     : 'param-array',
                prefix   : 'member',
            },
        },
    },

    RegisterInstancesWithLoadBalancer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_RegisterInstancesWithLoadBalancer.html',
        defaults : {
            Action : 'RegisterInstancesWithLoadBalancer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            Instances : {
                required : true,
                type     : 'param-array-of-objects',
                setName  : 'Instances.member',
            },
        },
    },

    // check capitalisation
    SetLoadBalancerListenerSslCertificate : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_SetLoadBalancerListenerSSLCertificate.html',
        defaults : {
            Action : 'SetLoadBalancerListenerSSLCertificate'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            LoadBalancerPort : {
                required : true,
                type     : 'param',
            },
            SslCertificateId : {
                name     : 'SSLCertificateId',
                required : true,
                type     : 'param',
            },
        },
    },

    SetLoadBalancerPoliciesForBackendServer : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_SetLoadBalancerPoliciesForBackendServer.html',
        defaults : {
            Action : 'SetLoadBalancerPoliciesForBackendServer'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            InstancePort : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            PolicyNames : {
                required : true,
                type     : 'param-array',
                prefix   : 'member'
            },
        },
    },

    SetLoadBalancerPoliciesOfListener : {
        url : 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/API_SetLoadBalancerPoliciesOfListener.html',
        defaults : {
            Action : 'SetLoadBalancerPoliciesOfListener'
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            LoadBalancerName : {
                required : true,
                type     : 'param',
            },
            LoadBalancerPort : {
                required : true,
                type     : 'param',
            },
            PolicyNames : {
                required : true,
                type     : 'param-array',
                prefix   : 'member'
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
