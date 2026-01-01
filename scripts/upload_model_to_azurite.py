"""
Upload trained model to Azurite (local Azure Storage emulator)
"""

import os
from azure.storage.blob import BlobServiceClient

# Azurite connection string
connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"

# Model file path (from ml_pipeline)
model_path = os.path.join(
    os.path.dirname(__file__), "..", "src", "ml_pipeline", "models", "model.pkl"
)

print(f"Connecting to Azurite...")
blob_service_client = BlobServiceClient.from_connection_string(connection_string)

# Create container if it doesn't exist
container_name = "models"
print(f"Creating container '{container_name}' if it doesn't exist...")
try:
    container_client = blob_service_client.create_container(container_name)
    print(f"Container '{container_name}' created")
except Exception as e:
    if "ContainerAlreadyExists" in str(e):
        print(f"Container '{container_name}' already exists")
        container_client = blob_service_client.get_container_client(container_name)
    else:
        raise

# Upload model
blob_name = "model_v1.pkl"
print(f"Uploading {model_path} to {container_name}/{blob_name}...")

blob_client = blob_service_client.get_blob_client(
    container=container_name, blob=blob_name
)

with open(model_path, "rb") as data:
    blob_client.upload_blob(data, overwrite=True)

print(f"✅ Model uploaded successfully to Azurite!")
print(f"   Container: {container_name}")
print(f"   Blob: {blob_name}")
