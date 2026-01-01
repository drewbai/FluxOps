"""
FluxOps ML Pipeline - Model Training Script
Trains a simple ML model and saves it for deployment
"""
import os
import json
import logging
from datetime import datetime
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class MLPipeline:
    """ML Pipeline for training and evaluating models"""
    
    def __init__(self, model_dir='models', log_dir='logs'):
        self.model_dir = model_dir
        self.log_dir = log_dir
        self.model = None
        self.metrics = {}
        
        # Create directories
        os.makedirs(self.model_dir, exist_ok=True)
        os.makedirs(self.log_dir, exist_ok=True)
    
    def generate_sample_data(self, n_samples=1000):
        """Generate synthetic data for demonstration"""
        logger.info(f"Generating {n_samples} synthetic samples...")
        
        np.random.seed(42)
        
        # Generate features
        X = np.random.randn(n_samples, 10)
        
        # Generate target with some pattern
        y = (X[:, 0] + X[:, 1] > 0).astype(int)
        
        # Create DataFrame
        feature_names = [f'feature_{i}' for i in range(10)]
        df = pd.DataFrame(X, columns=feature_names)
        df['target'] = y
        
        logger.info(f"Data shape: {df.shape}")
        logger.info(f"Target distribution:\n{df['target'].value_counts()}")
        
        return df
    
    def train_model(self, X_train, y_train, **kwargs):
        """Train the model"""
        logger.info("Training Random Forest model...")
        
        # Initialize model
        self.model = RandomForestClassifier(
            n_estimators=kwargs.get('n_estimators', 100),
            max_depth=kwargs.get('max_depth', 10),
            random_state=42,
            n_jobs=-1
        )
        
        # Train
        self.model.fit(X_train, y_train)
        logger.info("Model training completed")
        
        return self.model
    
    def evaluate_model(self, X_test, y_test):
        """Evaluate model performance"""
        logger.info("Evaluating model...")
        
        # Predictions
        y_pred = self.model.predict(X_test)
        
        # Calculate metrics
        accuracy = accuracy_score(y_test, y_pred)
        report = classification_report(y_test, y_pred, output_dict=True)
        conf_matrix = confusion_matrix(y_test, y_pred)
        
        self.metrics = {
            'accuracy': float(accuracy),
            'classification_report': report,
            'confusion_matrix': conf_matrix.tolist(),
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Model Accuracy: {accuracy:.4f}")
        logger.info(f"Classification Report:\n{classification_report(y_test, y_pred)}")
        
        return self.metrics
    
    def save_model(self, filename='model.pkl'):
        """Save trained model"""
        model_path = os.path.join(self.model_dir, filename)
        joblib.dump(self.model, model_path)
        logger.info(f"Model saved to {model_path}")
        
        return model_path
    
    def save_metrics(self, filename='metrics.json'):
        """Save evaluation metrics"""
        metrics_path = os.path.join(self.log_dir, filename)
        
        with open(metrics_path, 'w') as f:
            json.dump(self.metrics, f, indent=2)
        
        logger.info(f"Metrics saved to {metrics_path}")
        
        return metrics_path
    
    def run(self):
        """Execute complete ML pipeline"""
        logger.info("=" * 50)
        logger.info("Starting FluxOps ML Pipeline")
        logger.info("=" * 50)
        
        # Generate data
        df = self.generate_sample_data(n_samples=1000)
        
        # Split features and target
        X = df.drop('target', axis=1)
        y = df['target']
        
        # Train-test split
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        logger.info(f"Train set: {X_train.shape}, Test set: {X_test.shape}")
        
        # Train model
        self.train_model(X_train, y_train, n_estimators=100, max_depth=10)
        
        # Evaluate model
        self.evaluate_model(X_test, y_test)
        
        # Save model and metrics
        model_path = self.save_model()
        metrics_path = self.save_metrics()
        
        logger.info("=" * 50)
        logger.info("Pipeline completed successfully!")
        logger.info(f"Model: {model_path}")
        logger.info(f"Metrics: {metrics_path}")
        logger.info("=" * 50)
        
        return {
            'model_path': model_path,
            'metrics_path': metrics_path,
            'metrics': self.metrics
        }


if __name__ == '__main__':
    pipeline = MLPipeline()
    results = pipeline.run()
