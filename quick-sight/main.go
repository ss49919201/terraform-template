package main

import (
	_ "embed"
	"fmt"
	"os"
	"text/template"
)

//go:generate go run .

type dataBuilder struct {
	region string
}

func (d dataBuilder) build() data {
	return data{
		Region: d.region,
	}
}

func (d *dataBuilder) withRegion(v string) *dataBuilder {
	d.region = v
	return d
}

type data struct {
	Region string
}

//go:embed main.gotmpl
var tmplData string

func main() {
	// テンプレートを解析する
	tmpl, err := template.New("template").Parse(tmplData)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	f, err := os.Create("main.tf")
	if err != nil {
		fmt.Println("Error:", err)
	}

	// テンプレートを実行して、結果を出力する
	if err := tmpl.Execute(
		f,
		(&dataBuilder{}).withRegion("ap-northeast-1").build(),
	); err != nil {
		fmt.Println("Error:", err)
		return
	}
}
