#!/bin/bash 

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


# This shell script executes application tests and fails pipeline if tests fail
#------------------------------------------------------------------------------
# Argument1: APP_NAME
# Argument2: ENVIRONMENT
#------------------------------------------------------------------------------

# Get parameter values
APP_NAME=$1
ENVIRONMENT=$2

# Check number of parameters equals 2
if [ "$#" -ne 2 ]; then
    echo "ERROR: [Test Code] Illegal number of parameters"
    exit 1
fi

# Remove special characters from app name
APP_NAME=${APP_NAME//[_-]/}
# Convert ENVIRONMENT value to lowercase
ENVIRONMENT=`echo "$ENVIRONMENT" | sed 's/./\L&/g'`

# Execute Application Tests
# Run docker-compose up command. Replace default directory name with APP_NAME
if [ $ENVIRONMENT == "prod" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-prod.yml -p "${APP_NAME}${ENVIRONMENT}" up test
elif [ $ENVIRONMENT == "dev" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-dev.yml -p "${APP_NAME}${ENVIRONMENT}" up test
elif [ $ENVIRONMENT == "test" ]
then
   sudo /opt/bin/docker-compose -f docker-compose-test.yml -p "${APP_NAME}${ENVIRONMENT}" up test
fi;

# Check Status
STATUS=$(sudo docker wait ${APP_NAME}${ENVIRONMENT}_test_1)
if [ "$STATUS" != "0" ]; then
   echo " Tests FAILED: $STATUS"
   sudo docker rm -vf ${APP_NAME}${ENVIRONMENT}_test_1
   sudo docker rmi -f ${APP_NAME}${ENVIRONMENT}_test
   sudo docker rmi -f  ${APP_NAME}${ENVIRONMENT}_compile
   exit 1
else
   echo " Tests PASSED"
   sudo docker rm ${APP_NAME}${ENVIRONMENT}_test_1
   exit 0
fi
