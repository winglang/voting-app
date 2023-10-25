/** 
 * Post-synthesis function to configure AWS provider for LocalStack
 */

const { Aspects } = require("cdktf");

class LocalStackAspect {
    endpoint = "localhost.localstack.cloud:4566"

    constructor() {
    }
  
    // This method is called on every Construct within the specified scope (resources, data sources, etc.).
    visit(node) {        
        if (node.terraformResourceType == "aws_lambda_function") {
            node.node.scope._env['AWS_ENDPOINT_URL'] = "http://host.docker.internal:4566";
            node.node.scope._env['AWS_ENDPOINT_URL_DYNAMODB'] = "http://host.docker.internal:4566";
        }
    }
  }

exports.preSynth = function(app) {
  // app is the root node of the construct tree
  Aspects.of(app).add(new LocalStackAspect());
}


exports.postSynth = function(config) {    
    const endpoint = "http://localhost:4566";
    const services = [
        "apigateway", "apigatewayv2", "cloudformation", "cloudwatch", "dynamodb", "ec2", "es", 
        "elasticache", "firehose", "iam", "kinesis", "lambda", "rds", "redshift", "route53", 
        "secretsmanager", "ses", "sns", "sqs", "ssm", "stepfunctions", "sts", "cloudfront",
        "events", "logs"
    ];

    let endpoints = {};
    services.forEach(service => {
        endpoints[service] = endpoint;
    });

    endpoints["s3"] = "http://s3.localhost.localstack.cloud:4566";

    config.provider.aws = {
        access_key: "test",
        secret_key: "test",
        region: "us-east-1",
        s3_use_path_style: false,
        skip_credentials_validation: true,
        skip_metadata_api_check: true,
        skip_requesting_account_id: true,
        endpoints
    }

    return config;
}