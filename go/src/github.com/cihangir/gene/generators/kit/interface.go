package kit

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

func GenerateInterface(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	return generate(context, s, InterfaceTemplate, "interface")
}
