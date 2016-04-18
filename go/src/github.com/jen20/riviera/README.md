## Riviera

Riviera is an opinionated Azure Resource Manager API client for Go. The primary purpose at the current time is to easily implement support for services which the official client does not support.

Riviera explictly tries to provide a consistent API model informed by real-world usage. Some examples of this:

- Riviera exposes an RPC-style Request-Response semantic around operations on the API, rather than exposing the REST API
- Executing commands abstracts the asynchronous nature of some calls, minimizing boilerplate.
- Flat structures are returned, again minimizing boilerplate.

Riviera makes use of third-party libraries where possible - notably:
- `go-retryablehttp` (HashiCorp)
- `go-cleanhttp` (HashiCorp)
- `mapstructure` (mitchellh)
- `seq` (abdullin) [Test]

### How is this different from azure-sdk-for-go

Riviera offers a higher level of abstraction around the ARM API than the `azure-sdk-for-go`.

For example, on a storage account resource, `azure-sdk-for-go` exposes an `Update` operation. However, there are three different documented update operations which may be carried out, each of which has a different payload. Riviera offers three different `UpdateStorageAccount*` commands each tailored to an available operation.

That said, Riviera is less flexible than the `azure-sdk-for-go`, and considerably less complete in some areas (though more complete in others) - so this may inform which you wish to use.

### How do I use Riviera?

Some code:

1. Initialize a client using ARM credentials

        creds := &azure.AzureResourceManagerCredentials{
            ClientID:       os.Getenv("ARM_CLIENT_ID"),
            ClientSecret:   os.Getenv("ARM_CLIENT_SECRET"),
            TenantID:       os.Getenv("ARM_TENANT_ID"),
            SubscriptionID: os.Getenv("ARM_SUBSCRIPTION_ID"),
        }

        azureClient, err := azure.NewClient(creds)
        if err != nil {
            log.Fatal(err)
        }

1. Construct a request and a command. Note the use of `azure.String("string")` as a convenience method for obtaining a pointer to a string

        r.Command = sql.CreateOrUpdateServer{
            ResourceGroupName:          resourceGroupName,
            Name:                       "rivieradbservertest",
            Location:                   azure.WestUS,
            AdministratorLogin:         azure.String("hello"),
            AdministratorLoginPassword: azure.String("thisIsDog11'"),
            Version:                    azure.String("12.0"),
        }

1. Execute the request, and check for technical errors. Note that error response codes such as 404 does not count as an error here - it is often an expected response which must be handled explicitly

        response, err := r.Execute()
        if err != nil {
            log.Fatal(err)
        }

1. Check whether the request was successful or not and take action accordingly

        if response.IsSuccessful() {
            result := response.Parsed.(*sql.CreateOrUpdateServerResponse)

            log.Printf("Created SQL Server %q\n", result.Name)
            log.Printf("\tID: %s\n", result.ID)
            log.Printf("\tFQDN: %s\n", result.FullyQualifiedDomainName)
            log.Printf("\tFQDN: %s\n", result.State)
        } else {
            log.Printf("Failed creating SQL Server: %s", result.Error)
        }

### How do I implement a new API operation?

1. Create a file in the applicable service package named with the operation name in `snake_case`. For example, `sql/create_or_update_server.go`

1. Define the command structure. Name and ResourceName are used for URL construction and must be ignored by the JSON Marshaler. Similarly, `Location` and `Tags` are used for constructing the request envelope, and must be marked with the `riviera` tag. Other parameters are passed in the `properties` map in the request body and must be mapped correctly as per the API documentation
        
        type CreateOrUpdateServer struct {
            Name                       string             `json:"-"`
            ResourceGroupName          string             `json:"-"`
            Location                   string             `json:"-" riviera:"location"`
            Tags                       map[string]*string `json:"-" riviera:"tags"`
            AdministratorLogin         *string            `json:"administratorLogin,omitempty"`
            AdministratorLoginPassword *string            `json:"administratorLoginPassword,omitempty"`
            Version                    *string            `json:"version,omitempty"`
        }

1. Define the response structure. Use `mapstructure` tags to define where in the response fields will come from. ARM buries most useful information in the `properties` map in responses - Riviera will flatten this map before decoding with `mapstructure`, so unless in an exceptional case there is no need to worry about this.

        type CreateOrUpdateServerResponse struct {
            ID                         *string `mapstructure:"id"`
            Name                       *string `mapstructure:"name"`
            Location                   *string `mapstructure:"location"`
            Kind                       *string `mapstructure:"kind"`
            FullyQualifiedDomainName   *string `mapstructure:"fullyQualifiedDomainName"`
            AdministratorLogin         *string `mapstructure:"administratorLogin"`
            AdministratorLoginPassword *string `mapstructure:"administratorLoginPassword"`
            ExternalAdministratorLogin *string `mapstructure:"externalAdministratorLogin"`
            ExternalAdministratorSid   *string `mapstructure:"externalAdministratorSid"`
            Version                    *string `mapstructure:"version"`
            State                      *string `mapstructure:"state"`
        }

1. Implement the `APICall` interface for the command. The `URLPathFunc` argument makes use of the Name and Resource Group Name attributes to construct a URL, and the `APIInfo` method determines the HTTP Method will be used. The `ResponseTypeFunc` function returns an instance of the response structure defined above, or `nil` if there is no response type.

        func (s CreateOrUpdateServer) APIInfo() azure.APIInfo {
            return azure.APIInfo{
                APIVersion:  apiVersion,
                Method:      "PUT",
                URLPathFunc: sqlServerDefaultURLPath(s.ResourceGroupName, s.Name),
                ResponseTypeFunc: func() interface{} {
                    return &CreateOrUpdateServerResponse{}
                },
            }
        }
