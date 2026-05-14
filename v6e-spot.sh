#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
NC='\033[0m'

ZONES=("asia-northeast1-b" "asia-south1-c" "asia-southeast1-b" "europe-west4-a" "southamerica-east1-c" "southamerica-west1-a" "us-central1-b" "us-east5-a" "us-east5-b" "us-south1-c")

mapfile -t BILLING_LIST < <(gcloud billing accounts list --format="value(name)" --filter="open=true")

if [ ${#BILLING_LIST[@]} -eq 0 ]; then
    echo -e "${R}❌ Critical: Billing Account Not Found!${NC}"
    exit 1
fi

PROJECT_IDS=()
PROJECT_COUNT=1
TOTAL_BILLING=${#BILLING_LIST[@]}

echo -e "\n${B}💠 INITIALIZING PROJECTS${NC}"

for CURRENT_BILLING in "${BILLING_LIST[@]}"; do
    echo -e "\n${Y}💳 Active in Billing:${NC} ${G}$CURRENT_BILLING${NC}"

    for i in {1..3}; do
        RANDOM_STR=$(head /dev/urandom | tr -dc a-z0-9 | head -c 4)
        PROJECT_ID="cluster-${PROJECT_COUNT}-${RANDOM_STR}"
        PROJECT_IDS+=("$PROJECT_ID")

        echo -e "${Y}🛠️  Provisioning [${PROJECT_COUNT}]:${NC} ${G}$PROJECT_ID${NC}"

        if gcloud projects create "$PROJECT_ID" --name="cluster-$PROJECT_COUNT" --quiet; then
            sleep 2

            gcloud billing projects link "$PROJECT_ID" --billing-account="$CURRENT_BILLING" --quiet
            sleep 2

            echo -e "  ${B}⚙️  Enabling APIs...${NC}"
            gcloud services enable compute.googleapis.com tpu.googleapis.com --project="$PROJECT_ID" --quiet
        else
            echo -e "${R}❌ Failed Creating Project. Check Project Quota.${NC}"
            continue 
        fi

        ((PROJECT_COUNT++))
    done
done

echo -ne "\n${Y}⏳ Waiting for API propagation (15 seconds)... "
for i in {15..1}; do
    echo -ne "${R}$i ${NC}"
    sleep 1
    echo -ne "\b\b\b"
done
echo -e "${G}READY TO GO! ⚡${NC}\n"

echo -e "${B}🌌 DEPLOYING TPU CLUSTER${NC}"
for PROJECT_ID in "${PROJECT_IDS[@]}"; do
    echo -e "\n${B}▶️  Active Project:${NC} ${G}$PROJECT_ID${NC}"
    for z in "${ZONES[@]}"; do
        NAME="node-$z"
        echo -e "  ${Y}🛰️  Deploying:${NC} $NAME ${B}→${NC} $z"

        gcloud alpha compute tpus queued-resources create "$NAME" \
            --project="$PROJECT_ID" \
            --zone="$z" \
            --accelerator-type="v6e-8" \
            --runtime-version="tpu-ubuntu2204-base" \
            --node-count=2 \
            --provisioning-model=spot \
            --best-effort \
            --metadata-from-file=startup-script=script.sh \
            --scopes="https://www.googleapis.com/auth/cloud-platform" \
            --async --quiet
    done
done

echo -e "\n${G}✨ DONE ✨${NC}"
