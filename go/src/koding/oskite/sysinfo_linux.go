package oskite

// #include <sys/sysinfo.h>
import "C"

func GetTotalRAM() int {
	var info C.struct_sysinfo
	C.sysinfo(&info)
	return int(info.totalram) * int(info.mem_unit)
}
