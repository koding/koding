package main

func getUserLimit(username string) (float64, error) {
	return storage.GetUserLimit(username)
}

func saveUserLimit(username string, limit float64) error {
	return storage.SaveUserLimit(username, limit)
}
