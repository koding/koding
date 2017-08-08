package terraform

import (
	"reflect"
	"strings"
	"sync"
	"testing"
)

func TestContext2Input(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-vars")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "us-west-2",
			"amis": []map[string]interface{}{
				map[string]interface{}{
					"us-east-1": "override",
				},
			},
		},
		UIInput: input,
	})

	input.InputReturnMap = map[string]string{
		"var.foo": "us-east-1",
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	actual := strings.TrimSpace(state.String())
	expected := strings.TrimSpace(testTerraformInputVarsStr)
	if actual != expected {
		t.Fatalf("expected:\n%s\ngot:\n%s", expected, actual)
	}
}

func TestContext2Input_moduleComputedOutputElement(t *testing.T) {
	m := testModule(t, "input-module-computed-output-element")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		return c, nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestContext2Input_badVarDefault(t *testing.T) {
	m := testModule(t, "input-bad-var-default")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Config["foo"] = "bar"
		return c, nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestContext2Input_provider(t *testing.T) {
	m := testModule(t, "input-provider")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	var actual interface{}
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Config["foo"] = "bar"
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		actual = c.Config["foo"]
		return nil
	}
	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Apply(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !reflect.DeepEqual(actual, "bar") {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestContext2Input_providerMulti(t *testing.T) {
	m := testModule(t, "input-provider-multi")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	var actual []interface{}
	var lock sync.Mutex
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Config["foo"] = "bar"
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		lock.Lock()
		defer lock.Unlock()
		actual = append(actual, c.Config["foo"])
		return nil
	}
	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Apply(); err != nil {
		t.Fatalf("err: %s", err)
	}

	expected := []interface{}{"bar", "bar"}
	if !reflect.DeepEqual(actual, expected) {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestContext2Input_providerOnce(t *testing.T) {
	m := testModule(t, "input-provider-once")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	count := 0
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		count++
		return nil, nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if count != 1 {
		t.Fatalf("should only be called once: %d", count)
	}
}

func TestContext2Input_providerId(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-provider")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		UIInput: input,
	})

	var actual interface{}
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		v, err := i.Input(&InputOpts{Id: "foo"})
		if err != nil {
			return nil, err
		}

		c.Config["foo"] = v
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		actual = c.Config["foo"]
		return nil
	}

	input.InputReturnMap = map[string]string{
		"provider.aws.foo": "bar",
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Apply(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !reflect.DeepEqual(actual, "bar") {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestContext2Input_providerOnly(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-provider-vars")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "us-west-2",
		},
		UIInput: input,
	})

	input.InputReturnMap = map[string]string{
		"var.foo": "us-east-1",
	}

	var actual interface{}
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Config["foo"] = "bar"
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		actual = c.Config["foo"]
		return nil
	}

	if err := ctx.Input(InputModeProvider); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	if !reflect.DeepEqual(actual, "bar") {
		t.Fatalf("bad: %#v", actual)
	}

	actualStr := strings.TrimSpace(state.String())
	expectedStr := strings.TrimSpace(testTerraformInputProviderOnlyStr)
	if actualStr != expectedStr {
		t.Fatalf("bad: \n%s", actualStr)
	}
}

func TestContext2Input_providerVars(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-provider-with-vars")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "bar",
		},
		UIInput: input,
	})

	input.InputReturnMap = map[string]string{
		"var.foo": "bar",
	}

	var actual interface{}
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Config["bar"] = "baz"
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		actual, _ = c.Get("foo")
		return nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Apply(); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !reflect.DeepEqual(actual, "bar") {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestContext2Input_providerVarsModuleInherit(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-provider-with-vars-and-module")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		UIInput: input,
	})

	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		if errs := c.CheckSet([]string{"access_key"}); len(errs) > 0 {
			return c, errs[0]
		}
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		return nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestContext2Input_varOnly(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-provider-vars")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "us-west-2",
		},
		UIInput: input,
	})

	input.InputReturnMap = map[string]string{
		"var.foo": "us-east-1",
	}

	var actual interface{}
	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		c.Raw["foo"] = "bar"
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		actual = c.Raw["foo"]
		return nil
	}

	if err := ctx.Input(InputModeVar); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	if reflect.DeepEqual(actual, "bar") {
		t.Fatalf("bad: %#v", actual)
	}

	actualStr := strings.TrimSpace(state.String())
	expectedStr := strings.TrimSpace(testTerraformInputVarOnlyStr)
	if actualStr != expectedStr {
		t.Fatalf("bad: \n%s", actualStr)
	}
}

func TestContext2Input_varOnlyUnset(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-vars-unset")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "foovalue",
		},
		UIInput: input,
	})

	input.InputReturnMap = map[string]string{
		"var.foo": "nope",
		"var.bar": "baz",
	}

	if err := ctx.Input(InputModeVar | InputModeVarUnset); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	actualStr := strings.TrimSpace(state.String())
	expectedStr := strings.TrimSpace(testTerraformInputVarOnlyUnsetStr)
	if actualStr != expectedStr {
		t.Fatalf("bad: \n%s", actualStr)
	}
}

func TestContext2Input_varWithDefault(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-var-default")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{},
		UIInput:   input,
	})

	input.InputFn = func(opts *InputOpts) (string, error) {
		t.Fatalf(
			"Input should never be called because variable has a default: %#v", opts)
		return "", nil
	}

	if err := ctx.Input(InputModeVar | InputModeVarUnset); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	actualStr := strings.TrimSpace(state.String())
	expectedStr := strings.TrimSpace(`
aws_instance.foo:
  ID = foo
  foo = 123
  type = aws_instance
	`)
	if actualStr != expectedStr {
		t.Fatalf("expected: \n%s\ngot: \n%s\n", expectedStr, actualStr)
	}
}

func TestContext2Input_varPartiallyComputed(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-var-partially-computed")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{
			"foo": "foovalue",
		},
		UIInput: input,
		State: &State{
			Modules: []*ModuleState{
				&ModuleState{
					Path: rootModulePath,
					Resources: map[string]*ResourceState{
						"aws_instance.foo": &ResourceState{
							Type: "aws_instance",
							Primary: &InstanceState{
								ID: "i-abc123",
								Attributes: map[string]string{
									"id": "i-abc123",
								},
							},
						},
					},
				},
				&ModuleState{
					Path: append(rootModulePath, "child"),
					Resources: map[string]*ResourceState{
						"aws_instance.mod": &ResourceState{
							Type: "aws_instance",
							Primary: &InstanceState{
								ID: "i-bcd345",
								Attributes: map[string]string{
									"id":    "i-bcd345",
									"value": "one,i-abc123",
								},
							},
						},
					},
				},
			},
		},
	})

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}
}

// Module variables weren't being interpolated during the Input walk.
// https://github.com/hashicorp/terraform/issues/5322
func TestContext2Input_interpolateVar(t *testing.T) {
	input := new(MockUIInput)

	m := testModule(t, "input-interpolate-var")
	p := testProvider("null")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn

	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"template": testProviderFuncFixed(p),
		},
		UIInput: input,
	})

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestContext2Input_hcl(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-hcl")
	p := testProvider("hcl")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"hcl": testProviderFuncFixed(p),
		},
		Variables: map[string]interface{}{},
		UIInput:   input,
	})

	input.InputReturnMap = map[string]string{
		"var.listed": `["a", "b"]`,
		"var.mapped": `{x = "y", w = "z"}`,
	}

	if err := ctx.Input(InputModeVar | InputModeVarUnset); err != nil {
		t.Fatalf("err: %s", err)
	}

	if _, err := ctx.Plan(); err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := ctx.Apply()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	actualStr := strings.TrimSpace(state.String())
	expectedStr := strings.TrimSpace(testTerraformInputHCL)
	if actualStr != expectedStr {
		t.Logf("expected: \n%s", expectedStr)
		t.Fatalf("bad: \n%s", actualStr)
	}
}

// adding a list interpolation in fails to interpolate the count variable
func TestContext2Input_submoduleTriggersInvalidCount(t *testing.T) {
	input := new(MockUIInput)
	m := testModule(t, "input-submodule-count")
	p := testProvider("aws")
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		UIInput: input,
	})

	p.InputFn = func(i UIInput, c *ResourceConfig) (*ResourceConfig, error) {
		return c, nil
	}
	p.ConfigureFn = func(c *ResourceConfig) error {
		return nil
	}

	if err := ctx.Input(InputModeStd); err != nil {
		t.Fatalf("err: %s", err)
	}
}
