package extramath

// Divmod computes the quotient and remainder of division of a by b.
func DivmodU64(a, b uint64) (quo, rem uint64)

func MulI64(a, b int64) (hi int64, lo uint64)

// Mul computes tha 128-bit product of a by b as hi<<64|lo.
func MulU64(a, b uint64) (hi, lo uint64)
