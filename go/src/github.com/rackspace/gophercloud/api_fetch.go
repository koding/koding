package gophercloud

import(
 "github.com/mitchellh/mapstructure"
)

//The default generic openstack api
var OpenstackApi = map[string]interface{}{
        "Name":      "nova",
	"UrlChoice": PublicURL,
}

// Api for use with rackspace
var RackspaceApi = map[string]interface{}{
	"Name":      "cloudServersOpenStack",
	"VersionId": "2",
	"UrlChoice": PublicURL,
}


//Populates an ApiCriteria struct with the api values
//from one of the api maps 
func PopulateApi(variant string) (ApiCriteria, error){
	var Api ApiCriteria
	var variantMap map[string]interface{}

	switch variant {
	case "":
		variantMap = OpenstackApi

	case "openstack":
		variantMap = OpenstackApi

	case "rackspace": 
		variantMap = RackspaceApi
	}

	err := mapstructure.Decode(variantMap,&Api)
		if err != nil{
			return Api,err
		}
	return Api, err 
}
