resource "aws_sfn_state_machine" "sfn_state_machine" {
  definition = jsonencode(
    {
      Comment = "A description of my state machine"
      StartAt = "ECS RunTask"
      States = {
        "ECS RunTask" = {
          Catch = [
            {
              ErrorEquals = [
                "States.ALL",
              ]
              Next = "Fail"
            },
          ]
          Next = "Lambda Invoke"
          Parameters = {
            Cluster        = "arn:aws:ecs:REGION:ACCOUNT_ID:cluster/MyECSCluster"
            LaunchType     = "FARGATE"
            TaskDefinition = "arn:aws:ecs:REGION:ACCOUNT_ID:task-definition/MyTaskDefinition:1"
          }
          Resource       = "arn:aws:states:::ecs:runTask"
          TimeoutSeconds = 1800
          Type           = "Task"
        }
        Fail = {
          Type = "Fail"
        }
        "Lambda Invoke" = {
          Catch = [
            {
              ErrorEquals = [
                "States.ALL",
              ]
              Next = "Fail"
            },
          ]
          Next       = "Success"
          OutputPath = "$.Payload"
          Parameters = {
            FunctionName = "arn:aws:lambda:ap-northeast-1:${var.aws_account_id}:function:stripe-webhook:$LATEST"
            "Payload.$"  = "$"
          }
          Resource = "arn:aws:states:::lambda:invoke"
          Retry = [
            {
              BackoffRate = 2
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 2
              MaxAttempts     = 6
            },
          ]
          Type = "Task"
        }
        Success = {
          Type = "Succeed"
        }
      }
    }
  )
  name     = "MyStateMachine"
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/service-role/StepFunctions-MyStateMachine-role-0d0ed0c8"
  tags     = {}
  tags_all = {}
  type     = "STANDARD"

  logging_configuration {
    include_execution_data = false
    level                  = "OFF"
  }

  tracing_configuration {
    enabled = false
  }
}
