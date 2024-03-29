
# GKE AI/ML infra: vLLM and Nvidia Triton Inference Server on GKE 

Serving Llama 2 models on GKE multi GPUs through Nvidia Triton Inference Server and vLLM

## Introduction

### Triton Inference Server

Triton Inference Server enables teams to deploy any AI model from multiple deep learning and machine learning frameworks, including TensorRT, TensorFlow, PyTorch, ONNX, OpenVINO, Python, RAPIDS FIL, and more. Triton supports inference across cloud, data center, edge and embedded devices on NVIDIA GPUs, x86 and ARM CPU, or AWS Inferentia. Triton Inference Server delivers optimized performance for many query types, including real time, batched, ensembles and audio/video streaming. Triton inference Server is part of NVIDIA AI Enterprise, a software platform that accelerates the data science pipeline and streamlines the development and deployment of production AI.

Major features include:

Supports multiple deep learning frameworks

Supports multiple machine learning frameworks

Concurrent model execution

Dynamic batching

Sequence batching and implicit state management for stateful models

Provides Backend API that allows adding custom backends and pre/post processing operations

Model pipelines using Ensembling or Business Logic Scripting (BLS)

HTTP/REST and GRPC inference protocols based on the community developed KServe protocol

A C API and Java API allow Triton to link directly into your application for edge and other in-process use cases

Metrics indicating GPU utilization, server throughput, server latency, and more
Triton support differnt backends, including Python backend and OpenLLM and vLLM engines. 


### vLLM engine

LLMs promise to fundamentally change how we use AI across all industries. However, actually serving these models is challenging and can be surprisingly slow even on expensive hardware. Today we are excited to introduce vLLM, an open-source library for fast LLM inference and serving. vLLM utilizes PagedAttention, our new attention algorithm that effectively manages attention keys and values. vLLM equipped with PagedAttention redefines the new state of the art in LLM serving: it delivers up to 24x higher throughput than HuggingFace Transformers, without requiring any model architecture changes.

Based on tests, vLLM batch inference performance much faster than Huggingface Text Generation Inference(TGI), also performs bettern than Triton Inference Server Python Backend

## Summary:
This tutorial walks through how to setup Llama2 and other hugging face based LLM models through Nvidia Inference Server based on GKE and GPU(Nvidia T4, L4 etc)

## Tutorial steps:

### Prerequisites
Huggingface account settings with HF API Token. You also need to have access permission granted for Llama2 LLM models. 
GCP project and access
You may need to raise GPU quota for L4

### Download the github repo, 
```
git clone https://github.com/llm-on-gke/triton-vllm-gke
cd $PWD/triton-vllm-gke
chmod +x create-cluster.sh
```
### Create the GKE cluster
update the create-cluster.sh script, to replace proper values for PROJECT_ID and HF_TOKEN

```
./create-cluster.sh
```

Run the following commands to upload model repository, replace your-bucket-name
```
gsutil mb gs://your-bucket-name
gsutil cp -r model_repository gs://your-bucket-name/model_repository
```

### Deploy kubernetes resources into GKE cluster
update the vllm-gke-deploy.yaml file if necessary:
right model name env:
env:
   - name: model_name
              value: meta-llama/Llama-2-7b-chat-hf

Update model repository URI in cloud storage:

args: ["tritonserver", "--model-store=gs://your-bucket-name/model_repository"
Execute the command to deploy inference deployment in GKE, update the HF_TOKEN values

```
kubectl apply -f vllm-gke-deploy.yaml -n triton
```
### Test out the batch inference:
#### Run cloud build to create testing container images:
Run following command to build testing client container to test llama 2 batch inference:

```
cd client
gcloud builds submit .
```
#### test GRPC client
```
kubectl run -it -n triton --image us-east1-docker.pkg.dev/your-project/gke-llm/triton-client --env="triton_ip=$TRITON_IP" triton-client 
```

```
kubectl exec -it -n triton triton-client -- bash
```

Once you in the container, update the grpc-client.py with the endpoint with the Service IP of generated. 
Then run the following command inside the testing container:
```
curl $TRITON_INFERENCE_SERVER_SERVICE_HOST:8000/v2
url $TRITON_INFERENCE_SERVER_SERVICE_HOST:8002/metrics
python3 grpc-client.py
```
If everything runs smoothly, there will be a results.txt file generated, you may check the contents of 

### Retrieve metrics from Triton Inference server port 8002:
Check the metrics exposed by Triton Inference Server, 
```
kubectl exec -it -n triton bash -- bash
```

Then run the following:
```
curl SERVICEIP:8002/metrics
```

You should see a list of metrics starting with nv_XXX


### Intialize GMP settings
run the following command, 
```
gcloud container clusters get-credentials triton-inference --location us-central1
kubectl edit operatorconfig -n gmp-public
```

Add the following section right above line start with metadata:

features:
      targetStatus:
        enabled: true


Then run the following command to create GMP PodMonitoring resource targeting deployed triton inference server.
```
gcloud container clusters get-credentials triton-inference --location us-central1
kubectl -n triton apply -f vllm-podmonitoring.yaml
```

#### Use cloud monitoring metric explorer to display Model inference metrics:
Go to Monitoring/Metric Explorer, switch to PromQL on the right side of console. 
In the query window, type nv_, you will see a list of Nvidia triton metrics available. 

Choose one of NV_ metric, and Click "Run QUery" button on right side, you will see the chart of this metric. 

### Use Grafana to visualize Model inference monitoring metrics


