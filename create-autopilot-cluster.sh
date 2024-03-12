# GKE Autopilot
export PROJECT_ID=<your-project-id>
export REGION=us-central1
export CLUSTER_NAME=triton-inference
export NAMESPACE=triton
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"


gcloud container clusters create-auto ${CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --release-channel=rapid \
  --no-enable-master-authorized-networks \
  --cluster-version 1.28 \
  --scopes="gke-default,storage-rw"

kubectl create ns $NAMESPACE
kubectl create serviceaccount triton --namespace $NAMESPACE
gcloud iam service-accounts add-iam-policy-binding triton-server@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[triton/triton]"

kubectl annotate serviceaccount triton \
    --namespace $NAMESPACE \
    iam.gke.io/gcp-service-account=triton-server@${PROJECT_ID}.iam.gserviceaccount.com