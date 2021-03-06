###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

## This tf renders the stage cloud config and uploads it to S3 bucket
## So that it can be downloaded on GoCD and processed by ami-baker module
## And can then used as the base cloud config for the AMI to be created.
## https://github.com/stakater/ami-baker

# Application
data "template_file" "stage-user-data" {
  template = "${file("./user-data/stage.tmpl.yaml")}" #path relative to build dir

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${module.config-bucket.bucket_name}"
    efs_dns = "${replace(element(split(",", module.efs-mount-targets.dns-names), 0), "/^(.+?)\\./", "")}"
    # Using first value in the comma-separated list and remove the availability zone
  }
}

resource "aws_s3_bucket_object" "stage-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "stage/cloud-config.tmpl.yaml"
  content = "${data.template_file.stage-user-data.rendered}"
}

# Upload filebeat template to s3 bucket
resource "aws_s3_bucket_object" "stage-filebeat-config-tmpl" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "worker/consul-templates/filebeat.ctmpl"
  source = "./data/worker/consul-templates/filebeat.ctmpl"
}

# Admiral
data "template_file" "admiral-user-data" {
  template = "${file("./user-data/admiral.tmpl.yaml")}" #path relative to build dir

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${module.config-bucket.bucket_name}"
    global_admiral_config_bucket="${data.terraform_remote_state.global-admiral.config-bucket-name}"
    module_name = "admiral"
  }
}

resource "aws_s3_bucket_object" "admiral-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "admiral/cloud-config.tmpl.yaml"
  content = "${data.template_file.admiral-user-data.rendered}"
}