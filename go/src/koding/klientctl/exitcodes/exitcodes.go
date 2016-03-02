// exitcodes is a collection of exit codes. *Do not change existing codes*
package exitcodes

// For Iotas it is **very important** that the order of the following series are
// not changed. If you do, you change every exit code following.
const (
	// Zero exit code, everything is happy
	Success int = 0

	// Exit codes start at 64, in compliance with:
	// http://www.tldp.org/LDP/abs/html/exitcodes.html
	RepairHandleOptionsErr        int = 64 + iota
	RepairInitServiceErr              // 65
	RepairInitSetupRepairersErr       // 66
	RepairRunSetupRepairersErr        // 67
	RepairSetupKlientErr              // 68
	RepairCheckMachineExistErr        // 69
	RepairInitDefaultRepairersErr     // 70
	RepairRunDefaultRepairersErr      // 71
)
