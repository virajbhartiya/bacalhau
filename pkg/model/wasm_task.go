package model

import (
	"strings"

	"github.com/ipld/go-ipld-prime/datamodel"
)

var _ JobType = (*WasmInputs)(nil)

type WasmInputs struct {
	Entrypoint string
	Parameters []string
	Modules    []Resource
	Mounts     IPLDMap[string, Resource] // Resource
	Outputs    IPLDMap[string, datamodel.Node]
	Env        IPLDMap[string, string]
}

func (wasm *WasmInputs) InputStorageSpecs(with string) ([]StorageSpec, error) {
	entryModule, err := parseResource(with)
	if err != nil {
		return nil, err
	}
	inputs := []StorageSpec{parseStorageSource("/job", entryModule)}

	inputData, err := parseInputs(wasm.Mounts)
	if err != nil {
		return nil, err
	}
	inputs = append(inputs, inputData...)
	return inputs, nil
}

func (wasm *WasmInputs) OutputStorageSpecs(_ string) ([]StorageSpec, error) {
	outputs := make([]StorageSpec, 0, len(wasm.Outputs.Values))
	for path := range wasm.Outputs.Values {
		outputs = append(outputs, StorageSpec{
			Path: path,
			Name: strings.Trim(path, "/"),
		})
	}
	return outputs, nil
}

func (wasm *WasmInputs) EngineSpec(_ string) (EngineSpec, error) {
	params := make(map[string]interface{})
	params["EntryPoint"] = wasm.Entrypoint
	params["Parameters"] = wasm.Parameters
	params["EnvironmentVariables"] = wasm.Env.Values

	importModules := make([]StorageSpec, 0, len(wasm.Modules))
	for _, resource := range wasm.Modules {
		resource := resource
		importModules = append(importModules, parseStorageSource("", &resource))
	}
	params["ImportModules"] = importModules

	return EngineSpec{
		Type:   EngineWasm,
		Params: params,
	}, nil
}
