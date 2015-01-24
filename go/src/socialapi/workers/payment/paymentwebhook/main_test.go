package main

var controller *Controller

func init() {
	r := initializeRunner()
	conf := r.Conf

	// initialize client to talk to kloud
	kiteClient := initializeKiteClient(r.Kite, conf.Kloud.SecretKey, conf.Kloud.Address)

	// initialize client to send email
	email := initializeEmail(conf.Email)

	// initialize controller to inject dependencies
	cont := &Controller{Kite: kiteClient, Email: email}

	controller = cont
}
