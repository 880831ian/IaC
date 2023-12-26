#!/bin/bash

echo "stages:
 - plan
 - apply

default:
  image:
    name: alpine/terragrunt

before_script:
  - export GOOGLE_APPLICATION_CREDENTIALS=${ACCOUNT_KEY}
" >job.yml

generate_plan_job() {
  PROJECT_URL="$1"
  PARENT_PIPELINE_ID="$2"
  JOB_NAME="$3"
  echo "plan:${PROJECT_URL}:
  stage: plan  
  tags:
    - standard
  script:
    - cd projects/${PROJECT_URL}
    - terragrunt validate
    - terragrunt refresh
    - terragrunt plan -out=tfplan
  needs:
    - pipeline: \"${PARENT_PIPELINE_ID}\"
      job: ${JOB_NAME}      
  artifacts:
    paths:
      - projects/${PROJECT_URL}
    expire_in: \"3600\"
  " >>job.yml
}

generate_apply_job() {
  PROJECT_URL="$1"
  PARENT_PIPELINE_ID="$2"
  echo "apply:${PROJECT_URL}:
  stage: apply
  tags:
    - standard
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
  generate_plan_job "$PROJECT_URL" "$PARENT_PIPELINE_ID" "$2"
  generate_apply_job "$PROJECT_URL" "$PARENT_PIPELINE_ID"
done
