#!/bin/bash

source "$(dirname ${0})/common.sh"

OUTPUT_FILE_U=${1:-"untagged_resources.csv"}
OUTPUT_FILE_I=${2:-"ignored_resources.csv"}
UNTAGGED_RESOURCES=$(aws resource-explorer-2 search --query-string="region:us-east-1 -tag.key:${TAG_KEY}")


####################
# Helper Functions #
####################

# Helper function to get the list of ARNs from a given ResourceType
function get_arn_list {
    echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.ResourceType == \"${1}\") | .Arn" | replace_spaces
}

# Helper function to determine if a resource is valid after a threshold from the last reported date
function is_resource_valid {
    local last_reported_date=$(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn == \"${1}\") | .LastReportedAt")
    local elapsed=$(get_elapsed "${last_reported_date}")
    
    [[ ${elapsed} -le ${RESOURCE_VALID_THRESHOLD} ]] && return 0 || return 1
}

# Helper function to support the retrieval of untagged EC2-related resources
function _get_untagged_ec2_base {
    # Retrieve the list of EC2 resources (e.g., ENI) and their metadata (e.g., security group, VPC, etc.)
    local arns=($(get_arn_list "${1}"))
    local ids=$(echo $(echo ${arns[@]} | tr ' ' '\n' | cut -d'/' -f2) | tr ' ' ',')
    local list=$(aws ec2 ${2} --filters Name=${3},Values=${ids} 2>/dev/null)
    local list_size=$(echo ${list} | jq ".${4}[].${5}" | wc -l)

    # Try to guess the tag by selecting the Security Group and VPC IDs
    local resource_ids
    local resource_ids_alt
    for i in $(seq 0 1 $((${list_size}-1))); do
        local group_id=$(echo ${list} | jq -r ".${4}[$i].${6}" 2>/dev/null)
        local vpc_id=$(echo ${list} | jq -r ".${4}[$i].VpcId" 2>/dev/null)
        
        if [[ -z ${vpc_id} || ${vpc_id} == "null" ]]; then
            vpc_id=$(aws ec2 describe-security-groups --filters Name=group-id,Values=${group_id} | jq -r ".SecurityGroups[0].VpcId")
        fi

        resource_ids=(${resource_ids[@]} ${group_id:-"null"})
        resource_ids_alt=(${resource_ids_alt[@]} ${vpc_id:-"null"})
    done

    # Keep only the unique resource IDs and obtain the associated tags
    local resource_ids_all=$(echo ${resource_ids[@]} ${resource_ids_alt[@]} | tr ' ' '\n' | grep -v "null" | sort | uniq | tr '\n' ',' | sed -r "s|^(.*),$|\1|")
    local tag_list=$(aws ec2 describe-tags --filters Name=resource-id,Values=${resource_ids_all} Name=tag:${TAG_KEY},Values=*)

    # Given the list of tags from the properties of the previous step, associate them with each ARN
    for i in $(seq 0 1 $((${list_size}-1))); do
        local id=$(echo ${list} | jq -r ".${4}[$i].${5}")
        local arn=$(echo ${arns[@]} | tr ' ' '\n' | grep ${id})
        
        local tag=$(echo ${tag_list} | jq -r ".Tags[] | select(.ResourceId == \"${resource_ids[$i]}\") | .Value" 2>/dev/null)
        [[ -z ${tag} ]] && tag=$(echo ${tag_list} | jq -r ".Tags[] | select(.ResourceId == \"${resource_ids_alt[$i]}\") | .Value" 2>/dev/null)
        
        # If we reach this point and we still don't have a tag, let's try to guess it from the description
        [[ -z ${tag} ]] && tag=$(resource_to_tag "$(echo ${list} | jq -r ".${4}[$i].Description")")

        output "${arn}" "${tag}"
    done
}


#############################
# Untagged Lookup Functions #
#############################

# Function to get the list of untagged Elastic Network Interfaces and their potential owner
function get_untagged_eni {
    _get_untagged_ec2_base "ec2:network-interface" \
                           "describe-network-interfaces" \
                           "network-interface-id" \
                           "NetworkInterfaces" \
                           "NetworkInterfaceId" \
                           "Groups[0].GroupId"
}

# Function to get the list of untagged Security Groups and their potential owner
function get_untagged_sg {
    _get_untagged_ec2_base "ec2:security-group" \
                           "describe-security-groups" \
                           "group-id" \
                           "SecurityGroups" \
                           "GroupId" \
                           "GroupId"
}

# Function to get the list of untagged Security Group Rules and their potential owner
function get_untagged_sgr {
    _get_untagged_ec2_base "ec2:security-group-rule" \
                           "describe-security-group-rules" \
                           "security-group-rule-id" \
                           "SecurityGroupRules" \
                           "SecurityGroupRuleId" \
                           "GroupId"
}

# Function to get the list of untagged ACLs and their potential owner
function get_untagged_acl {
    _get_untagged_ec2_base "ec2:network-acl" \
                           "describe-network-acls" \
                           "network-acl-id" \
                           "NetworkAcls" \
                           "NetworkAclId" \
                           "VpcId"
}

# Function to get the list of untagged Route Tables and their potential owner
function get_untagged_rtb {
    _get_untagged_ec2_base "ec2:route-table" \
                           "describe-route-tables" \
                           "route-table-id" \
                           "RouteTables" \
                           "RouteTableId" \
                           "VpcId"
}

# Function to get the list of untagged EC2 Launch Templates and their potential owner
function get_untagged_lt {
    local arns=($(get_arn_list "ec2:launch-template"))
    local ids=($(echo ${arns[@]} | tr ' ' '\n' | cut -d'/' -f2))

    # Try to guess the tag by selecting the properties from each Launch Template version
    for i in $(seq 0 1 $((${#arns[@]}-1))); do
        local arn=${arns[$i]}
        local id=${ids[$i]}
        local lt_description=$(aws ec2 describe-launch-template-versions --launch-template-id "${id}")

        local tag=$(echo ${lt_description} | \
                    jq -r ".LaunchTemplateVersions[].LaunchTemplateData.TagSpecifications[].Tags[] | select(.Key == \"${TAG_KEY}\") | .Value" | \
                    sort | uniq)
        
        # If we reach this point and we still don't have a tag, let's try to guess it from the name
        [[ -z ${tag} ]] && tag=$(resource_to_tag "$(echo ${lt_description} | jq -r ".LaunchTemplateVersions[].LaunchTemplateName")")

        output "${arn}" "${tag}"
    done
}

# Function to get the list of untagged EC2 Placement Groups and their potential owner
function get_untagged_pg {
    local arns=($(get_arn_list "ec2:placement-group"))
    local ids=($(echo ${arns[@]} | tr ' ' '\n' | cut -d'/' -f2))
    local list=$(aws ec2 describe-placement-groups --group-ids ${ids[@]} 2>/dev/null)
    local list_size=$(echo ${list} | jq ".PlacementGroups[].GroupId" | wc -l)

    # Try to guess the tag by selecting the properties from each EC2 Placement Group
    for i in $(seq 0 1 $((${list_size}-1))); do
        local id=$(echo ${list} | jq -r ".PlacementGroups[$i].GroupId")
        local arn=$(echo ${arns[@]} | tr ' ' '\n' | grep ${id})
        local pg_name=$(echo ${list} | jq -r ".PlacementGroups[$i].GroupName")

        # As there is not much information to query, let's try to guess the tag from the name
        output "${arn}" "$(resource_to_tag "${pg_name}")"
    done
}

# Function to get the list of untagged ECS Task Definitions and their potential owner
function get_untagged_td {
    local arns=($(get_arn_list "ecs:task-definition"))

    # Try to guess the tag by selecting the properties from each ECS Task Definition
    for arn in ${arns[@]}; do
        local td_description=$(aws ecs describe-task-definition --task-definition "${arn}")
        local exec_role=$(echo ${td_description} | jq -r ".taskDefinition.executionRoleArn" | cut -d'/' -f2)
        
        local tag=$(aws iam list-role-tags --role-name "${exec_role}" | jq -r ".Tags[] | select(.Key == \"${TAG_KEY}\") | .Value")

        # If we reach this point and we still don't have a tag, let's try to guess it from the name
        [[ -z ${tag} ]] && tag=$(resource_to_tag "$(echo ${td_description} | jq -r ".taskDefinition.containerDefinitions[].name")")

        # As there is not much information to query, let's try to guess the tag from the name
        output "${arn}" "${tag}"
    done
}

# Function to get the list of untagged CloudWatch Alarms and their potential owner
function get_untagged_alarm {
    local names=($(get_arn_list "cloudwatch:alarm" | sed -r "s|.*:([^:]+)|\1|"))

    # Try to guess the tag by certain properties such as the ECS Cluster Name or the name of the alarm itself
    for _name in ${names[@]}; do
        local name=$(restore_spaces "${_name}")
        local description=$(aws cloudwatch describe-alarms --alarm-names "${name}" 2>/dev/null)

        # The AWS CLI does not complain if you provide an empty list, incorrectly returning all of the alarms
        [[ $(echo ${description} | jq ".MetricAlarms[].AlarmName" | wc -l) -ne 1 ]] && continue

        local alarm_arn=$(echo ${description} | jq -r ".MetricAlarms[].AlarmArn")
        local resource_name=$(echo ${description} | jq -r ".MetricAlarms[].Dimensions[] | select(.Name == \"ClusterName\") | .Value" 2>/dev/null)
        [[ -z ${resource_name} ]] && resource_name=$(echo ${description} | jq -r ".MetricAlarms[].AlarmName")

        output "${alarm_arn}" "$(resource_to_tag "${resource_name}")"
    done
}

# Function to get the list of untagged CloudWatch Log Groups and their potential owner
function get_untagged_loggroup {
    # As there is not much information to query for Log Groups, guess the tag by using the ARN
    for loggroup_arn in $(get_arn_list "logs:log-group"); do
        output "${loggroup_arn}" "$(resource_to_tag "${loggroup_arn}")"
    done
}

# Function to get the list of untagged EC2 Key-Pairs and their potential owner
function get_untagged_keypair {
    local keypair_arns=($(get_arn_list "ec2:key-pair"))
    local keypair_ids=$(echo $(echo ${keypair_arns[@]} | tr ' ' '\n' | cut -d'/' -f2) | tr ' ' ',')
    local keypair_list=$(aws ec2 describe-key-pairs --filters Name=key-pair-id,Values=${keypair_ids})

    # Try to guess the tag by the name of the resource
    for i in $(seq 0 1 $(($(echo ${keypair_list} | jq ".KeyPairs[].KeyPairId" | wc -l)-1))); do
        local keypair_arn=$(echo ${keypair_arns[@]} | tr ' ' '\n' | grep $(echo ${keypair_list} | jq -r ".KeyPairs[$i].KeyPairId"))
        local keypair_name=$(echo ${keypair_list} | jq -r ".KeyPairs[$i].KeyName")

        output "${keypair_arn}" "$(resource_to_tag "${keypair_name}")"
    done
}

# Function to get the list of untagged KMS Keys and their potential owner
function get_untagged_kms_key {
    local kms_key_arns=($(get_arn_list "kms:key"))

    # As there is not much information to query, guess the tag by using the description or the alias
    for kms_key_arn in ${kms_key_arns[@]}; do
        local kms_key_id=$(echo ${kms_key_arn} | cut -d'/' -f2)
        local kms_key_description=$(aws kms describe-key --key-id "${kms_key_id}")

        # Ignore AWS-managed entries, as apparently they cannot be manually tagged
        [[ $(echo ${kms_key_description} | jq -r ".KeyMetadata.KeyManager") == "AWS" ]] && continue

        local tag=$(resource_to_tag "$(echo ${kms_key_description} | jq -r ".KeyMetadata.Description")")
        if [[ ${tag} == ${TAG_UNKNOWN} ]]; then
            kms_key_alias=$(aws kms list-aliases --key-id "${kms_key_id}" | jq -r ".Aliases[].AliasName")
            tag=$(resource_to_tag "${kms_key_alias}")
        fi

        output "${kms_key_arn}" "${tag}"
    done
}

# Function to get the list of untagged ECS Container Instances and their potential owner
function get_untagged_ecs_ci {
    local ecs_ci_arns=($(get_arn_list "ecs:container-instance"))

    # Try to guess the tag by using the subnet attachment or the name of the resource
    for ecs_ci_arn in ${ecs_ci_arns[@]}; do
        local ecs_ci_cluster=$(echo ${ecs_ci_arn} | sed -r "s|^.*container-instance/([^/]+)/.+$|\1|")
        local ecs_ci_description=$(aws ecs describe-container-instances --cluster ${ecs_ci_cluster} \
                                                                        --container-instances "${ecs_ci_arn}" 2>/dev/null)

        # If the instance is not running, ensure it is not older than a threshold (i.e., Resource Explorer requires time to update)
        if [[ ${ecs_ci_description} == *"\"reason\": \"MISSING\""* ]]; then
            is_resource_valid "${ecs_ci_arn}" || continue  # Ignore entry if not valid

            # Within the threshold, add suffix to ARN for further verification
            ecs_ci_arn="${ecs_ci_arn}${ARN_UNKNOWN_SUFFIX}"
        else
            local ecs_ci_subnet=$(echo ${ecs_ci_description} | jq -r ".containerInstances[].attachments[0].details[] | select(.name == \"subnetId\") | .value" 2>/dev/null)
            local ecs_ci_subnet_tags=$(aws ec2 describe-tags --filters Name=resource-id,Values=${ecs_ci_subnet})

            local tag=$(echo ${ecs_ci_subnet_tags} | jq -r ".Tags[] | select(.Key == \"${TAG_KEY}\") | .Value" 2>/dev/null)
        fi

        # If we reach this point and we still don't have a tag, let's try to guess it from the ARN
        [[ -z ${tag} ]] && tag=$(resource_to_tag "${ecs_ci_arn}")

        output "${ecs_ci_arn}" "${tag}"
        unset tag  # Prevents assigning incorrect tags to missing resources
    done
}

# Function to get the list of untagged ElastiCache Parameter Groups and their potential owner
function get_untagged_ecache_pg {
    local pg_arns=($(get_arn_list "elasticache:parametergroup"))

    # As there is not much information to query, guess the tag by using the description
    for pg_arn in ${pg_arns[@]}; do
        # Ignore default entries, as apparently they cannot be manually tagged
        [[ ${pg_arn} == *"parametergroup:default"* ]] && continue

        local pg_name=$(echo ${pg_arn} | sed -r "s|^.*:parametergroup:(.*)$|\1|")
        local pg_description=$(aws elasticache describe-cache-parameter-groups --cache-parameter-group-name "${pg_name}" | \
                               jq -r ".CacheParameterGroups[].Description")

        output "${pg_arn}" "$(resource_to_tag "${pg_description}")"
    done
}

# Function to get the list of untagged ElastiCache Users and their potential owner
function get_untagged_ecache_usr {
    local usr_arns=($(get_arn_list "elasticache:user"))

    # As there is not much information to query, guess the tag by using the name
    for usr_arn in ${usr_arns[@]}; do
        local usr_id=$(echo ${usr_arn} | sed -r "s|^.*:user:(.*)$|\1|")
        local usr_name=$(aws elasticache describe-users --user-id "${usr_id}" | jq -r ".Users[].UserName")

        output "${usr_arn}" "$(resource_to_tag "${usr_name}")"
    done
}

# Function to get the list of untagged Elastic Load Balancing Listener Rules and their potential owner
function get_untagged_elb_lr {
    local lr_arns=($(get_arn_list "elasticloadbalancing:listener-rule/app"))

    for lr_arn in ${lr_arns[@]}; do
        local l_arn=$(echo ${lr_arn} | sed -r "s|(^.*elasticloadbalancing.*listener)-rule(.*)/[^/]+$|\1\2|")
        local l_tags=$(aws elbv2 describe-tags --resource-arns "${l_arn}" 2>/dev/null)

        # If the rule no longer exists, ensure it is not older than a threshold (i.e., Resource Explorer requires time to update)
        if [[ -z ${l_tags} ]]; then
            is_resource_valid "${lr_arn}" || continue  # Ignore entry if not valid

            # Within the threshold, add suffix to ARN for further verification
            lr_arn="${lr_arn}${ARN_UNKNOWN_SUFFIX}"
        fi

        # Check whether or not the Listener itself contains the tag key
        local tag=$(echo ${l_tags} | jq -r ".TagDescriptions[] | .Tags[] | select(.Key == \"${TAG_KEY}\") | .Value" 2>/dev/null)

        # If we reach this point and we still don't have a tag, let's try to guess it from the ARN
        [[ -z ${tag} ]] && tag=$(resource_to_tag "${lr_arn}")

        output "${lr_arn}" "${tag}"
    done
}

# Function to get the list of untagged EventBridge Event Buses and their potential owner
function get_untagged_ebr_bus {
    local ebr_bus_arns=($(get_arn_list "events:event-bus"))

    # As there is not much information to query, guess the tag by using the name
    for ebr_bus_arn in ${ebr_bus_arns[@]}; do
        local ebr_bus_name=$(aws events describe-event-bus --name "${ebr_bus_arn}" | jq -r ".Name")
        output "${ebr_bus_arn}" "$(resource_to_tag "${ebr_bus_name}")"
    done
}

# Function to get the list of untagged EventBridge Rules and their potential owner
function get_untagged_ebr_rule {
    local ebr_rule_arns=($(get_arn_list "events:rule"))

    # As there is not much information to query, guess the tag by using the description
    for ebr_rule_arn in ${ebr_rule_arns[@]}; do
        local ebr_rule_name=$(echo ${ebr_rule_arn} | cut -d'/' -f2)
        local ebr_rule_description=$(aws events describe-rule --name "${ebr_rule_name}")

        # Ignore AWS-managed entries, as apparently they cannot be manually tagged
        [[ $(echo ${ebr_rule_description} | jq -r ".ManagedBy") == *".amazonaws.com" ]] && continue

        output "${ebr_rule_arn}" "$(resource_to_tag "$(echo "${ebr_rule_description}" | jq -r ".Description")")"
    done
}

# Function to get the list of untagged Lambda Functions and their potential owner
function get_untagged_lambda_fn {
    local lambda_fn_arns=($(get_arn_list "lambda:function"))

    for lambda_fn_arn in ${lambda_fn_arns[@]}; do
        # Try to guess the tag by retrieving the Security Group of the function
        local lambda_fn_description=$(aws lambda get-function --function-name "${lambda_fn_arn}")
        local lambda_fn_sg=$(echo ${lambda_fn_description} | jq -r ".Configuration.VpcConfig.SecurityGroupIds[0]" 2>/dev/null)

        local tag=$(aws ec2 describe-security-groups --filters Name=group-id,Values=${lambda_fn_sg} | \
                    jq -r ".SecurityGroups[].Tags[] | select(.Key == \"${TAG_KEY}\") | .Value" 2>/dev/null)

        # If we still don't have a tag, let's try to guess it from the Log Group or alternatively the ARN
        [[ -z ${tag} ]] && tag=$(resource_to_tag "$(echo ${lambda_fn_description} | jq -r ".Configuration.LoggingConfig.LogGroup")")
        [[ ${tag} == ${TAG_UNKNOWN} ]] && tag=$(resource_to_tag "${lambda_fn_arn}")
        
        output "${lambda_fn_arn}" "${tag}"
    done
}

# Function to get the list of untagged MemoryDB Parameter Groups and their potential owner
function get_untagged_mdb_pg {
    local mdb_pg_arns=($(get_arn_list "memorydb:parametergroup"))

    # As there is not much information to query, guess the tag by using the description
    for mdb_pg_arn in ${mdb_pg_arns[@]}; do
        # Ignore default entries, as apparently they cannot be manually tagged
        [[ ${mdb_pg_arn} == *"parametergroup/default"* ]] && continue

        local mdb_pg_name=$(echo ${mdb_pg_arn} | cut -d'/' -f2)
        local mdb_pg_description=$(aws memorydb describe-parameter-groups --parameter-group-name "${mdb_pg_name}" | \
                                   jq -r ".ParameterGroups[].Description")
        
        output "${mdb_pg_arn}" "$(resource_to_tag "${mdb_pg_description}")"
    done
}

# Function to get the list of untagged MemoryDB Users and their potential owner
function get_untagged_mdb_usr {
    local mdb_usr_arns=($(get_arn_list "memorydb:user"))

    # As there is not much information to query, guess the tag by using the name
    for mdb_usr_arn in ${mdb_usr_arns[@]}; do
        local mdb_usr_name=$(echo ${mdb_usr_arn} | cut -d'/' -f2)
        local mdb_usr=$(aws memorydb describe-users --user-name "${mdb_usr_name}" | jq -r ".Users[].Name")
        output "${mdb_usr_arn}" "$(resource_to_tag "${mdb_usr}")"
    done
}

# Function to get the list of untagged RDS Parameter Groups and their potential owner
function get_untagged_rds_pg {
    local rds_pg_arns=($(get_arn_list "rds:pg"))

    # As there is not much information to query, guess the tag by using the description
    for rds_pg_arn in ${rds_pg_arns[@]}; do
        local rds_pg_name=$(echo ${rds_pg_arn} | sed -r "s|.*:([^:]+)|\1|")
        local rds_pg_description=$(aws rds describe-db-parameter-groups --db-parameter-group-name "${rds_pg_name}" |
                                   jq -r ".DBParameterGroups[].Description")
        
        output "${rds_pg_arn}" "$(resource_to_tag "${rds_pg_description}")"
    done
}

# Function to get the list of untagged RDS Cluster Parameter Groups and their potential owner
function get_untagged_rds_cpg {
    local rds_cpg_arns=($(get_arn_list "rds:cluster-pg"))

    # As there is not much information to query, guess the tag by using the description
    for rds_cpg_arn in ${rds_cpg_arns[@]}; do
        local rds_cpg_name=$(echo ${rds_cpg_arn} | sed -r "s|.*:([^:]+)|\1|")
        local rds_cpg_description=$(aws rds describe-db-cluster-parameter-groups --db-cluster-parameter-group-name "${rds_cpg_name}" |
                                    jq -r ".DBClusterParameterGroups[].Description")
        
        output "${rds_cpg_arn}" "$(resource_to_tag "${rds_cpg_description}")"
    done
}

# Function to get the list of untagged RDS Option Groups and their potential owner
function get_untagged_rds_og {
    local rds_og_arns=($(get_arn_list "rds:og"))

    # As there is not much information to query, guess the tag by using the description
    for rds_og_arn in ${rds_og_arns[@]}; do
        local rds_og_name=$(echo ${rds_og_arn} | sed -r "s|.*:og:(.*)$|\1|")
        local rds_og_description=$(aws rds describe-option-groups --option-group-name "${rds_og_name}" |
                                   jq -r ".OptionGroupsList[].OptionGroupDescription")
        
        output "${rds_og_arn}" "$(resource_to_tag "${rds_og_description}")"
    done
}

# Function to get the list of untagged RDS Security Groups and their potential owner
function get_untagged_rds_sg {
    local rds_sg_arns=($(get_arn_list "rds:secgrp"))

    # As there is not much information to query, guess the tag by using the description
    for rds_sg_arn in ${rds_sg_arns[@]}; do
        local rds_sg_name=$(echo ${rds_sg_arn} | sed -r "s|.*:([^:]+)|\1|")
        local rds_sg_description=$(aws rds describe-db-security-groups --db-security-group-name "${rds_sg_name}" | \
                                   jq -r ".DBSecurityGroups[].DBSecurityGroupDescription")
        
        output "${rds_sg_arn}" "$(resource_to_tag "${rds_sg_description}")"
    done
}

# Function to get the list of untagged S3 Access Points and their potential owner
# Important: The resource below is ignored, as there is no mechanism for us to tag the resource
# function __IGNORED__ get_untagged_s3_ap {
#     local s3_ap_arns=($(get_arn_list "s3:accesspoint"))
#
#     for s3_ap_arn in ${s3_ap_arns[@]}; do
#         # Try to guess the tag by using the associated S3 bucket
#         local s3_account_id=$(echo ${s3_ap_arn} | sed -r "s|.*:([0-9]+):accesspoint.*|\1|")
#         local s3_ap_name=$(echo ${s3_ap_arn} | cut -d'/' -f2)
#         local s3_bucket=$(aws s3control get-access-point --account-id "${s3_account_id}" --name "${s3_ap_name}" | jq -r ".Bucket")
#
#         local tag=$(aws s3api get-bucket-tagging --bucket "${s3_bucket}" | jq -r ".TagSet[] | select(.Key == \"${TAG_KEY}\") | .Value" 2>/dev/null)
#
#         # If we still don't have a tag, let's try to guess it from the ARN
#         [[ -z ${tag} ]] && tag=$(resource_to_tag "${s3_ap_arn}")
#
#         output "${s3_ap_arn}" "${tag}"
#     done
# }

# Function to get the list of untagged EC2 EBS Volumes and their potential owner
function get_untagged_vol {
    local vol_arns=($(get_arn_list "ec2:volume"))

    for vol_arn in ${vol_arns[@]}; do
        # Try to guess the tag by using the attached EC2 instance
        local vol_id=$(echo ${vol_arn} | cut -d'/' -f2)
        local instance_id=$(aws ec2 describe-volumes --volume-ids "${vol_id}" 2>/dev/null | jq -r ".Volumes[0].Attachments[0].InstanceId")

        # If we do not have an instance or the volume does not exist, ignore
        [[ -z ${instance_id} ]] && continue

        local instance_tags=$(aws ec2 describe-tags --filters Name=resource-id,Values=${instance_id})
        local tag=$(echo ${instance_tags} | jq -r ".Tags[] | select(.Key == \"${TAG_KEY}\") | .Value" 2>/dev/null)

        # If we still don't have a tag, let's try to guess it from the name of the instance
        [[ -z ${tag} ]] && tag=$(resource_to_tag "$(echo ${instance_tags} | jq -r ".Tags[] | select(.Key == \"Name\") | .Value" 2>/dev/null)")
        
        output "${vol_arn}" "${tag}"
    done
}


######################
# Main Functionality #
######################

# Append the output from each 'get_untagged_*' function into a temporary file
run_script_fns "tag verification" "get_untagged_"

# Generate the output CSV with all of the deducted tags, if any
output_result_csv ${OUTPUT_FILE_U}

# Generate the output CSV with all of the ignored/erroneous resources, if any
if [[ -f ${OUTPUT_FILE_U} ]]; then
    arn_filter="$(echo -n $(sed 1d ${OUTPUT_FILE_U} | cut -d${CSV_SEP} -f1 | sed "s|${ARN_UNKNOWN_SUFFIX}||g") | tr ' ' '|')"
    echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[].Arn" | grep -v -E "${arn_filter}" | \
                                 sed -r "s|(.*)|\1${CSV_SEP}${TAG_IGNORED}|" > ${OUTPUT_FILE_TMP}
else
    echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[].Arn" | sed -r "s|(.*)|\1${CSV_SEP}${TAG_IGNORED}|" > ${OUTPUT_FILE_TMP}
fi

output_result_csv ${OUTPUT_FILE_I}

# Finally, provide a summary of the results obtained
num_resources_untagged=$(sed 1d ${OUTPUT_FILE_U} 2>/dev/null | wc -l)
num_resources_ignored=$(sed 1d ${OUTPUT_FILE_I}  2>/dev/null | wc -l)
echo -e "\n\n\nFound ${num_resources_untagged} resources untagged and ${num_resources_ignored} additional resources" \
        "ignored / not available.\nSee next CI jobs for further information and downloadable artifacts."
