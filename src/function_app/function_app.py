import azure.functions as func
import logging
import json
import os
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
import joblib
import numpy as np

app = func.FunctionApp()


@app.route(route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    logging.info('Health check endpoint called')
    
    return func.HttpResponse(
        json.dumps({
            "status": "healthy",
            "service": "FluxOps ML Pipeline",
            "version": "1.0.0"
        }),
        mimetype="application/json",
        status_code=200
    )


@app.route(route="predict", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def predict(req: func.HttpRequest) -> func.HttpResponse:
    """ML model prediction endpoint"""
    logging.info('Prediction endpoint called')
    
    try:
        # Parse request body
        req_body = req.get_json()
        features = req_body.get('features')
        
        if not features:
            return func.HttpResponse(
                json.dumps({"error": "Missing 'features' in request body"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validate features
        if len(features) != 10:
            return func.HttpResponse(
                json.dumps({"error": "Expected 10 features"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Load model from blob storage
        model = load_model_from_blob()
        
        # Make prediction
        X = np.array(features).reshape(1, -1)
        prediction = model.predict(X)[0]
        probability = model.predict_proba(X)[0]
        
        result = {
            "prediction": int(prediction),
            "probability": {
                "class_0": float(probability[0]),
                "class_1": float(probability[1])
            },
            "confidence": float(max(probability))
        }
        
        logging.info(f'Prediction result: {result}')
        
        return func.HttpResponse(
            json.dumps(result),
            mimetype="application/json",
            status_code=200
        )
        
    except ValueError as e:
        logging.error(f'Value error: {str(e)}')
        return func.HttpResponse(
            json.dumps({"error": f"Invalid input: {str(e)}"}),
            mimetype="application/json",
            status_code=400
        )
    except Exception as e:
        logging.error(f'Error processing prediction: {str(e)}')
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="model-info", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
def model_info(req: func.HttpRequest) -> func.HttpResponse:
    """Get model information"""
    logging.info('Model info endpoint called')
    
    try:
        # Get storage connection details
        storage_account = os.environ.get('STORAGE_ACCOUNT_NAME', 'N/A')
        
        info = {
            "model_name": "Random Forest Classifier",
            "model_version": "v1",
            "storage_account": storage_account,
            "container": "models",
            "blob_name": "model_v1.pkl",
            "features_required": 10,
            "classes": [0, 1]
        }
        
        return func.HttpResponse(
            json.dumps(info),
            mimetype="application/json",
            status_code=200
        )
        
    except Exception as e:
        logging.error(f'Error getting model info: {str(e)}')
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            mimetype="application/json",
            status_code=500
        )


@app.blob_trigger(arg_name="blob", path="models/model_v1.pkl",
                  connection="STORAGE_CONNECTION_STRING")
def model_updated(blob: func.InputStream):
    """Triggered when model is updated in blob storage"""
    logging.info(f'Model blob updated: {blob.name}')
    logging.info(f'Blob size: {blob.length} bytes')
    
    # Clear any cached models
    global _cached_model
    _cached_model = None
    
    logging.info('Model cache cleared, will reload on next prediction')


# Cache for loaded model
_cached_model = None


def load_model_from_blob():
    """Load model from Azure Blob Storage with caching"""
    global _cached_model
    
    if _cached_model is not None:
        logging.info('Using cached model')
        return _cached_model
    
    try:
        logging.info('Loading model from blob storage...')
        
        # Get connection string from environment
        connection_string = os.environ.get('STORAGE_CONNECTION_STRING')
        
        if not connection_string:
            raise ValueError("STORAGE_CONNECTION_STRING not set")
        
        # Create blob service client
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        
        # Get blob client
        blob_client = blob_service_client.get_blob_client(
            container='models',
            blob='model_v1.pkl'
        )
        
        # Download model to temp file
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pkl') as tmp_file:
            download_stream = blob_client.download_blob()
            tmp_file.write(download_stream.readall())
            tmp_file_path = tmp_file.name
        
        # Load model
        _cached_model = joblib.load(tmp_file_path)
        
        # Clean up temp file
        os.unlink(tmp_file_path)
        
        logging.info('Model loaded successfully')
        return _cached_model
        
    except Exception as e:
        logging.error(f'Failed to load model: {str(e)}')
        raise
