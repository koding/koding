package digitalocean

var dropletIds = make(chan uint, 10)

func GetDropletIdFromCache(name string, keyId, imageId uint) uint {
	// dropletInfo, err := d.CreateDroplet(dropletName, keyId, image.Id)
	// if err != nil {
	// 	return nil, err
	// }

	return 0
}
