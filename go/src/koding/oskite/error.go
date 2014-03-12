package oskite

type UnderMaintenanceError struct{}

func (err *UnderMaintenanceError) Error() string {
	return "VM is under maintenance."
}

type AccessDeniedError struct{}

func (err *AccessDeniedError) Error() string {
	return "Vm is banned"
}

type VMNotFoundError struct {
	Name string
}

func (err *VMNotFoundError) Error() string {
	return "There is no VM with hostname/id '" + err.Name + "'."
}
