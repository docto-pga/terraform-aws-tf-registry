resource "aws_api_gateway_rest_api" "root" {
  name = local.api_gateway_name
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.private.id]
  }
}

resource "aws_vpc_endpoint" "private" {
  service_name        = "com.amazonaws.eu-central-1.execute-api"
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_api_gateway_resource" "modules_root" {
  rest_api_id = aws_api_gateway_rest_api.root.id
  parent_id   = aws_api_gateway_rest_api.root.root_resource_id
  path_part   = "modules.v1"
}

module "modules_v1" {
  source = "./modules/modules.v1"

  rest_api_id        = aws_api_gateway_resource.modules_root.rest_api_id
  parent_resource_id = aws_api_gateway_resource.modules_root.id

  dynamodb_table_name     = local.modules_table_name
  dynamodb_query_role_arn = aws_iam_role.modules.arn

}

module "disco" {
  source = "./modules/disco"

  rest_api_id = aws_api_gateway_rest_api.root.id
  services = {
    "modules.v1" = "${aws_api_gateway_resource.modules_root.path}/",
  }
}

resource "aws_api_gateway_deployment" "live" {
  depends_on = [
    module.modules_v1,
    module.disco,
  ]

  rest_api_id = aws_api_gateway_rest_api.root.id
  stage_name  = "live"
}
