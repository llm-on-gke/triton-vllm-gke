
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
update the create-cluster.sh script with write parameters, and provision GKE cluster
comment out the following lines if you need public instead of private cluster:
  --enable-ip-alias \
  --enable-private-nodes  \
  --master-ipv4-cidr 172.16.0.32/28 \
  --scopes="gke-default,storage-rw"

```
./create-cluster.sh
```
### Update and upload the Llama 2 Model repository files.
Review and validate the following model configuration file under model_repository/vllm/1/vllm_engine_args.json, you may update model names, tensor_parralle_size for muti-gpu within a node

{
    "model":"meta-llama/Llama-2-13b-chat-hf",
    "disable_log_requests": "true",
    "tensor_parallel_size": 2,
    "gpu_memory_utilization": 0.8
}

Run the following commands to upload model repository, replace your-bucket-name
```
gsutil mb gs://your-bucket-name
gsutil cp -r model_repository gs://your-bucket-name/model_repository
```

### Run cloud build to create testing container images:
Run following command to build testing client container to test llama 2 batch inference:

```
cd client
gcloud builds submit .
```
### Deploy kubernetes resources into GKE cluster
Update the following line in llama2-gke-deploy.yaml file, with your model repository URI in cloud storage:

args: ["tritonserver", "--model-store=gs://your-bucket-name/model_repository"
Execute the command to deploy inference deployment in GKE, update the HF_TOKEN values

```
gcloud container clusters get-credentials llm-inference-l4 --location us-central1
export HF_TOKEN=<paste-your-own-token>
kubectl create secret generic llama2 --from-literal="HF_TOKEN=$HF_TOKEN" -n triton
kubectl apply -f llama2-gke-deploy.yaml -n triton
```
### Test out the batch inference:
```
kubectl run -it -n triton --image us-east1-docker.pkg.dev/your-project/triton-llm/vllm-client bash 
```

Once you in the container, update the client.py with the endpoint with the Service IP of generated. 
Then run the following command inside the testing container:
```
python3 client.py
```
If everything runs smoothly, there will be a results.txt file generated, you may check the contents of 
