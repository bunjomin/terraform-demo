locals {
  title = "demo-docker"
}

resource "aws_codestarconnections_connection" "github-connection" {
  name = "demo-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "demo" {
  name     = "${local.title}-pipeline"
  role_arn = aws_iam_role.demo-codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.demo-artifacts.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_alias.demo-artifacts.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["${local.title}-source"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github-connection.arn
        FullRepositoryId = "bunjomin/terraform-docker-demo"
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["${local.title}-source"]
      output_artifacts = ["${local.title}-build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.demo.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["${local.title}-build"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.demo.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.demo.deployment_group_name
        TaskDefinitionTemplateArtifact = "${local.title}-build"
        AppSpecTemplateArtifact        = "${local.title}-build"
      }
    }
  }
}


