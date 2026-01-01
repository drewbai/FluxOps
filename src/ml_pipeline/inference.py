"""
Model inference utilities for making predictions
"""
import joblib
import numpy as np
import logging

logger = logging.getLogger(__name__)


class ModelInference:
    """Handle model loading and inference"""
    
    def __init__(self, model_path):
        self.model_path = model_path
        self.model = None
        self.load_model()
    
    def load_model(self):
        """Load the trained model"""
        try:
            self.model = joblib.load(self.model_path)
            logger.info(f"Model loaded from {self.model_path}")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def predict(self, X):
        """Make predictions"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        predictions = self.model.predict(X)
        probabilities = self.model.predict_proba(X)
        
        return {
            'predictions': predictions.tolist(),
            'probabilities': probabilities.tolist()
        }
    
    def predict_single(self, features):
        """Predict for a single sample"""
        X = np.array(features).reshape(1, -1)
        result = self.predict(X)
        
        return {
            'prediction': result['predictions'][0],
            'probability': result['probabilities'][0]
        }


if __name__ == '__main__':
    # Example usage
    inference = ModelInference('models/model.pkl')
    
    # Test prediction
    sample_features = np.random.randn(10).tolist()
    result = inference.predict_single(sample_features)
    print(f"Prediction: {result}")
