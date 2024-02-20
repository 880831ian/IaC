#!/bin/bash

generate_status=${2}

echo "stages:
 - plan
 - apply

default:
  image:
    name: alpine/terragrunt
  tags:
    - terraform-runner

before_script:
  - export GOOGLE_APPLICATION_CREDENTIALS=${ACCOUNT_KEY}
" >job.yml

generate_plan_job() {
  PROJECT_URL="$1"
  PARENT_PIPELINE_ID="$2"
  echo "plan:${PROJECT_URL}:
  stage: plan  
  script:
    - cd projects/${PROJECT_URL}
    - terragrunt validate
    - terragrunt refresh
    - terragrunt plan -out=tfplan
  artifacts:
    paths:
      - projects/${PROJECT_URL}
    expire_in: \"3600\"
  rules:
    - if: '\$CI_PIPELINE_SOURCE == \"parent_pipeline\"'
  " >>job.yml
}

generate_apply_job() {
  PROJECT_URL="$1"
  PARENT_PIPELINE_ID="$2"
  echo "apply:${PROJECT_URL}:
  stage: apply
  script:
    - cd projects/${PROJECT_URL}
    - echo 'y' | terragrunt apply tfplan
  dependencies:
    - plan:${PROJECT_URL}
  when: manual
  " >>job.yml
}

IFS=',' read -ra PROJECT_URLS <<<"$1"
for PROJECT_URL in "${PROJECT_URLS[@]}"; do
  if [ "${generate_status}" == "plan" ]; then
    generate_plan_job "$PROJECT_URL" "$PARENT_PIPELINE_ID"
  else
    generate_plan_job "$PROJECT_URL" "$PARENT_PIPELINE_ID"
    generate_apply_job "$PROJECT_URL" "$PARENT_PIPELINE_ID"
  fi
done
