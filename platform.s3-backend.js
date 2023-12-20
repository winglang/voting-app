// plugin.static-backend.js

exports.postSynth = function(config) {
  config.terraform.backend = {
    s3: {
      bucket: "wing-voting-app-tfstate",
      region: "us-east-1",
      key: "terraform.tfstate",
      dynamodb_table: "wing-voting-app-tfstate-lock"
    }
  }
  return config;
}
