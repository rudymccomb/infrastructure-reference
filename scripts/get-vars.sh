#!/usr/bin/env bash

# Default Environment variables
COREOS_UPDATE_CHANNEL=${COREOS_UPDATE_CHANNEL}        # stable/beta/alpha
VM_TYPE=${VM_TYPE}                                        # hvm/pv - note: t1.micro supports only pv type

AWS_PROFILE=${AWS_PROFILE}
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_REGION=$($DIR/read_cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)

TF_STATE_BUCKET_NAME=${TF_STATE_BUCKET_NAME}
# Get options from the command line
while getopts ":c:z:t:" OPTION
do
    case $OPTION in
        c)
          COREOS_UPDATE_CHANNEL=$OPTARG
          ;;
        z)
          AWS_REGION=$OPTARG
          ;;
        t)
          VM_TYPE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -c <stable|beta|alpha> -z <aws zone> -t <hvm|pv>"
          exit 0
          ;;
    esac
done

#########################
# Preprossessing for terraform variable
# for current region's availability zones
###########################
# Map of AWS availability zones
declare -A AWS_AZS=(["us-east-1"]=${AZ_US_EAST_1}
				 ["us-west-1"]=${AZ_US_WEST_1}
				 ["us-west-2"]=${AZ_US_WEST_2}
				 ["eu-west-1"]=${AZ_EU_WEST_1}
				 ["eu-central-1"]=${AZ_EU_CETNRAL_1}
				 ["ap-southeast-1"]=${AZ_AP_SOUTHEAST_1}
				 ["ap-southeast-2"]=${AZ_AP_SOUTHEAST_2}
				 ["ap-south-1"]=${AZ_AP_SOUTH_1}
         ["ap-northeast-1"]=${AZ_AP_NORTHEAST_1}
				 ["ap-northeast-2"]=${AZ_AP_NORTHEAST_2}
				 ["sa-east-1"]=${AZ_SA_EAST_1})
IFS=',' read -r -a AVAIL_ZONES <<< "${AWS_AZS["${AWS_REGION}"]}"

# Converting array in the format: "us-east-1a","us-east-1c","us-east-1d"
array_length="${#AVAIL_ZONES[@]}"
tf_avail_zones=""
for i in "${!AVAIL_ZONES[@]}"; do
  tf_avail_zones="${tf_avail_zones} \"${AVAIL_ZONES[$i]}\""

  if [[ $i -lt $((array_length - 1)) ]]
  then
    tf_avail_zones="${tf_avail_zones},"
  fi
done
####################
####################


# Get the AMI id
url=`printf "http://%s.release.core-os.net/amd64-usr/current/coreos_production_ami_%s_%s.txt" $COREOS_UPDATE_CHANNEL $VM_TYPE $AWS_REGION`
cat <<EOF
# Generated by scripts/get-vars.sh
variable "ami" { default = "`curl -s $url`" }
variable "availability_zones" { default = [${tf_avail_zones} ] }
variable "tf_state_bucket_name" { default = "${TF_STATE_BUCKET_NAME}" }
EOF