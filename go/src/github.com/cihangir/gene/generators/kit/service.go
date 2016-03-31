package kit

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

func GenerateService(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	outputs, err := generate(context, s, ServiceTemplate, "service")
	if err != nil {
		return nil, err
	}

	for i := range outputs {
		// this is a stub, so if exists dont override
		outputs[i].DoNotOverride = true
	}

	return outputs, nil
}
