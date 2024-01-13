package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/quicksight"
	"github.com/aws/aws-sdk-go-v2/service/quicksight/types"
)

func main() {
	// AWSクライアントの作成
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		fmt.Println("Error loading AWS configuration:", err)
		return
	}

	// QuickSightサービスのクライアント作成
	client := quicksight.NewFromConfig(cfg)

	// 更新するDataSetの情報
	dataSetId := "test-id"
	dataSetname := "test-name"

	// 更新するDataSetの設定
	input := &quicksight.UpdateDataSetInput{
		AwsAccountId: aws.String(""),
		DataSetId:    aws.String(dataSetId),
		Name:         aws.String(dataSetname),
		ImportMode:   types.DataSetImportModeSpice,
		PhysicalTableMap: map[string]types.PhysicalTable{
			"test": &types.PhysicalTableMemberS3Source{
				Value: types.S3Source{
					DataSourceArn: aws.String(""),
					InputColumns: []types.InputColumn{
						{
							Name: aws.String("name"),
							Type: types.InputColumnDataTypeString,
						},
					},
					UploadSettings: &types.UploadSettings{
						Format: types.FileFormatCsv,
					},
				},
			},
		},
		DatasetParameters: []types.DatasetParameter{
			{
				StringDatasetParameter: &types.StringDatasetParameter{
					Id:        aws.String("string"),
					Name:      aws.String("string"),
					ValueType: types.DatasetParameterValueTypeSingleValued,
					DefaultValues: &types.StringDatasetParameterDefaultValues{
						StaticValues: []string{"string"},
					},
				},
				IntegerDatasetParameter: &types.IntegerDatasetParameter{
					Id:        aws.String("integer"),
					Name:      aws.String("integer"),
					ValueType: types.DatasetParameterValueTypeSingleValued,
					DefaultValues: &types.IntegerDatasetParameterDefaultValues{
						StaticValues: []int64{1},
					},
				},
			},
		},
	}

	// DataSetの更新リクエストを送信
	resp, err := client.UpdateDataSet(context.TODO(), input)
	if err != nil {
		fmt.Println("Error updating DataSet:", err)
		return
	}

	fmt.Println("DataSet updated successfully:", resp)
}
