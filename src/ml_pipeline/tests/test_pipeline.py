"""
Unit tests for ML pipeline
"""
import pytest
import numpy as np
import pandas as pd
from train_model import MLPipeline
from inference import ModelInference
import os
import tempfile
import shutil


@pytest.fixture
def temp_dirs():
    """Create temporary directories for testing"""
    model_dir = tempfile.mkdtemp()
    log_dir = tempfile.mkdtemp()
    
    yield model_dir, log_dir
    
    # Cleanup
    shutil.rmtree(model_dir, ignore_errors=True)
    shutil.rmtree(log_dir, ignore_errors=True)


@pytest.fixture
def pipeline(temp_dirs):
    """Create pipeline instance"""
    model_dir, log_dir = temp_dirs
    return MLPipeline(model_dir=model_dir, log_dir=log_dir)


def test_generate_sample_data(pipeline):
    """Test data generation"""
    df = pipeline.generate_sample_data(n_samples=100)
    
    assert df.shape[0] == 100
    assert df.shape[1] == 11  # 10 features + 1 target
    assert 'target' in df.columns
    assert df['target'].nunique() == 2


def test_train_model(pipeline):
    """Test model training"""
    df = pipeline.generate_sample_data(n_samples=100)
    X_train = df.drop('target', axis=1)
    y_train = df['target']
    
    model = pipeline.train_model(X_train, y_train)
    
    assert model is not None
    assert hasattr(model, 'predict')
    assert hasattr(model, 'predict_proba')


def test_evaluate_model(pipeline):
    """Test model evaluation"""
    df = pipeline.generate_sample_data(n_samples=100)
    X = df.drop('target', axis=1)
    y = df['target']
    
    pipeline.train_model(X, y)
    metrics = pipeline.evaluate_model(X, y)
    
    assert 'accuracy' in metrics
    assert 0 <= metrics['accuracy'] <= 1
    assert 'classification_report' in metrics
    assert 'confusion_matrix' in metrics


def test_save_model(pipeline):
    """Test model saving"""
    df = pipeline.generate_sample_data(n_samples=100)
    X = df.drop('target', axis=1)
    y = df['target']
    
    pipeline.train_model(X, y)
    model_path = pipeline.save_model()
    
    assert os.path.exists(model_path)
    assert model_path.endswith('.pkl')


def test_save_metrics(pipeline):
    """Test metrics saving"""
    df = pipeline.generate_sample_data(n_samples=100)
    X = df.drop('target', axis=1)
    y = df['target']
    
    pipeline.train_model(X, y)
    pipeline.evaluate_model(X, y)
    metrics_path = pipeline.save_metrics()
    
    assert os.path.exists(metrics_path)
    assert metrics_path.endswith('.json')


def test_full_pipeline(pipeline):
    """Test complete pipeline execution"""
    results = pipeline.run()
    
    assert 'model_path' in results
    assert 'metrics_path' in results
    assert 'metrics' in results
    assert os.path.exists(results['model_path'])
    assert os.path.exists(results['metrics_path'])


def test_inference(pipeline):
    """Test model inference"""
    # Train and save model
    df = pipeline.generate_sample_data(n_samples=100)
    X = df.drop('target', axis=1)
    y = df['target']
    
    pipeline.train_model(X, y)
    model_path = pipeline.save_model()
    
    # Load and predict
    inference = ModelInference(model_path)
    sample_features = np.random.randn(10).tolist()
    result = inference.predict_single(sample_features)
    
    assert 'prediction' in result
    assert 'probability' in result
    assert result['prediction'] in [0, 1]
    assert len(result['probability']) == 2
    assert sum(result['probability']) == pytest.approx(1.0)


def test_inference_batch(pipeline):
    """Test batch inference"""
    # Train and save model
    df = pipeline.generate_sample_data(n_samples=100)
    X = df.drop('target', axis=1)
    y = df['target']
    
    pipeline.train_model(X, y)
    model_path = pipeline.save_model()
    
    # Batch prediction
    inference = ModelInference(model_path)
    X_test = np.random.randn(5, 10)
    result = inference.predict(X_test)
    
    assert 'predictions' in result
    assert 'probabilities' in result
    assert len(result['predictions']) == 5
    assert len(result['probabilities']) == 5
