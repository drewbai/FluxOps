# AZ-204: Developing Solutions for Microsoft Azure
## Exam Objectives Mapping to FluxOps & FnCast Projects

This document maps the **AZ-204 certification exam objectives** to practical implementations in the **FluxOps** and **FnCast** projects, helping you understand which skills are demonstrated in each project.

---

## 📋 Exam Domain Overview

| Domain | Weight | FluxOps Coverage | FnCast Coverage | FluxOps Functions |
|--------|--------|------------------|-----------------|-------------------|
| **Develop Azure Compute Solutions** | 25-30% | ✅ Extensive | ✅ Extensive | `/health`, `/predict`, `/model-info` |
| **Develop for Azure Storage** | 15-20% | ✅ Extensive | ⚠️ Moderate | `/predict` (loads model from blob) |
| **Implement Azure Security** | 20-25% | ✅ Extensive | ✅ Extensive | All (use managed identity) |
| **Monitor, Troubleshoot, and Optimize** | 15-20% | ✅ Extensive | ⚠️ Moderate | All (App Insights telemetry) |
| **Connect to and Consume Azure Services** | 15-20% | ✅ Moderate | ✅ Extensive | `/predict` (blob storage) |

---

## 1️⃣ Develop Azure Compute Solutions (25-30%)

### 1.1 Implement containerized solutions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Create and manage container images | ❌ | ✅ | **FnCast**: Docker containerization, ACR integration | N/A |
| Run containers using Azure Container Instances | ❌ | ✅ | **FnCast**: ACI deployment scenarios | N/A |
| Publish an image to Azure Container Registry | ❌ | ✅ | **FnCast**: Automated image push to ACR | N/A |
| Implement Azure Container Apps | ❌ | ✅ | **FnCast**: Container Apps deployment | N/A |

**FluxOps Focus**: Serverless compute (Azure Functions)  
**FnCast Focus**: Container-based compute solutions

---

### 1.2 Implement Azure Functions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Create and configure an Azure Function App | ✅ | ✅ | **FluxOps**: `infra/terraform/modules/function_app/`<br>**FnCast**: Function app with HTTP triggers | All functions |
| Implement input and output bindings | ✅ | ✅ | **FluxOps**: Blob storage bindings in `function_app.py`<br>**FnCast**: Various trigger types | `/predict` (blob input) |
| Implement function triggers | ✅ | ✅ | **FluxOps**: HTTP triggers (`/health`, `/predict`, `/model-info`)<br>**FnCast**: Timer, Queue, HTTP triggers | `/health`, `/predict`, `/model-info` |
| Implement Azure Durable Functions | ❌ | ✅ | **FnCast**: Orchestrator/Activity patterns | N/A |

**Key Files**:
- FluxOps: `src/function_app/function_app.py`, `src/function_app/host.json`
- FluxOps Terraform: `infra/terraform/modules/function_app/main.tf`

---

## 2️⃣ Develop for Azure Storage (15-20%)

### 2.1 Develop solutions that use Azure Blob Storage

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Set and retrieve properties and metadata | ✅ | ⚠️ | **FluxOps**: Blob metadata for ML models | `/predict`, `/model-info` |
| Perform operations on data using SDK | ✅ | ⚠️ | **FluxOps**: Upload/download models in `train_model.py` | `/predict` (downloads model) |
| Implement storage policies and lifecycle management | ⚠️ | ❌ | **FluxOps**: Terraform configuration in storage module | N/A (infrastructure) |
| Implement Blob Storage encryption | ✅ | ❌ | **FluxOps**: Azure-managed encryption by default | All (encrypted storage) |

**Key Files**:
- FluxOps: `src/ml_pipeline/train_model.py` (blob operations)
- FluxOps: `infra/terraform/modules/storage/main.tf` (storage configuration)

---

### 2.2 Develop solutions that use Azure Cosmos DB

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Perform CRUD operations using SDK | ❌ | ✅ | **FnCast**: Cosmos DB integration for data persistence | N/A |
| Implement partitioning schemes | ❌ | ✅ | **FnCast**: Partition key strategies | N/A |
| Set consistency levels | ❌ | ✅ | **FnCast**: Consistency configuration | N/A |

**Focus**: FnCast demonstrates Cosmos DB extensively

---

## 3️⃣ Implement Azure Security (20-25%)

### 3.1 Implement user authentication and authorization

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Authenticate using Microsoft Identity platform | ⚠️ | ✅ | **FnCast**: Microsoft Entra ID authentication | `/predict` (function-level auth) |
| Implement OAuth2 authentication | ❌ | ✅ | **FnCast**: OAuth2 flows | N/A |
| Create and implement shared access signatures | ⚠️ | ✅ | **FnCast**: SAS token generation | N/A |

---

### 3.2 Implement secure Azure solutions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Secure app configuration data using Azure Key Vault | ✅ | ✅ | **FluxOps**: `infra/terraform/modules/key_vault/`<br>Stores storage keys, connection strings | All (access Key Vault) |
| Develop code using managed identities | ✅ | ✅ | **FluxOps**: System-assigned identity for Function App<br>Terraform: `identity` block in function_app module | All (use managed identity) |
| Implement solutions using Azure App Configuration | ❌ | ✅ | **FnCast**: Centralized configuration | N/A |

**Key Files**:
- FluxOps: `infra/terraform/modules/key_vault/main.tf`
- FluxOps: `infra/terraform/modules/function_app/main.tf` (managed identity)

**Security Highlights**:
- ✅ No hardcoded credentials
- ✅ RBAC with least privilege
- ✅ Secrets stored in Key Vault
- ✅ TLS 1.2+ enforced

---

## 4️⃣ Monitor, Troubleshoot, and Optimize (15-20%)

### 4.1 Implement caching for solutions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Configure cache and expiration policies | ❌ | ✅ | **FnCast**: Azure Cache for Redis | N/A |
| Implement secure caching using Azure Redis | ❌ | ✅ | **FnCast**: Redis with SSL/TLS | N/A |

---

### 4.2 Troubleshoot solutions using Application Insights

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Configure instrumentation for an app | ✅ | ✅ | **FluxOps**: `infra/terraform/modules/app_insights/`<br>Integrated with Function App | All (auto-instrumented) |
| Analyze and troubleshoot solutions using metrics and logs | ✅ | ⚠️ | **FluxOps**: Automatic telemetry collection<br>Query logs via Azure Portal | All (emit telemetry) |
| Implement Application Insights web tests and alerts | ⚠️ | ⚠️ | Both: Configured via Azure Portal/Terraform | `/health` (availability test) |

**Key Files**:
- FluxOps: `infra/terraform/modules/app_insights/main.tf`
- FluxOps: Application Insights configured with workspace-based model

---

## 5️⃣ Connect to and Consume Azure Services (15-20%)

### 5.1 Implement API Management

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Create APIM instance | ❌ | ✅ | **FnCast**: APIM gateway for Function Apps | N/A |
| Configure authentication for APIs | ❌ | ✅ | **FnCast**: OAuth, subscription keys | N/A |
| Define policies for APIs | ❌ | ✅ | **FnCast**: Rate limiting, caching policies | N/A |

---

### 5.2 Develop event-based solutions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Implement solutions using Azure Event Grid | ❌ | ✅ | **FnCast**: Event-driven architecture | N/A |
| Implement solutions using Azure Event Hub | ❌ | ✅ | **FnCast**: Stream processing | N/A |

---

### 5.3 Develop message-based solutions

| Objective | FluxOps | FnCast | Implementation Details | FluxOps Functions |
|-----------|---------|--------|------------------------|-------------------|
| Implement solutions using Azure Service Bus | ❌ | ✅ | **FnCast**: Queue-based messaging | N/A |
| Implement solutions using Azure Queue Storage | ⚠️ | ✅ | **FnCast**: Lightweight queuing | N/A |

---

## 📊 Project Comparison Summary

### FluxOps Strengths
✅ **Azure Functions** (HTTP triggers, bindings)  
✅ **Blob Storage** (SDK operations, lifecycle)  
✅ **Key Vault** (secrets management)  
✅ **Managed Identities** (authentication)  
✅ **Application Insights** (monitoring)  
✅ **Infrastructure as Code** (Terraform)  
✅ **CI/CD Automation** (GitHub Actions)  

**Best for learning**:
- Serverless compute patterns
- Secure secret management
- Blob storage operations
- Infrastructure automation
- ML pipeline deployment

---

### FnCast Strengths
✅ **Container-based solutions** (ACR, ACI, Container Apps)  
✅ **Cosmos DB** (NoSQL operations)  
✅ **Azure Service Bus** (messaging)  
✅ **Event Grid/Event Hub** (event-driven)  
✅ **API Management** (gateway patterns)  
✅ **Durable Functions** (orchestration)  
✅ **Microsoft Entra ID** (authentication)  

**Best for learning**:
- Container deployment strategies
- Event-driven architectures
- Message queue patterns
- API gateway design
- NoSQL database operations

---

## 🎯 Study Strategy

### Week 1-2: Compute Solutions
- [ ] **FluxOps**: Study Function App implementation (`src/function_app/`)
- [ ] **FluxOps**: Review Terraform function_app module
- [ ] **FnCast**: Explore container deployment patterns
- [ ] **FnCast**: Practice Durable Functions orchestration

### Week 3: Storage Solutions
- [ ] **FluxOps**: Review blob operations in `train_model.py`
- [ ] **FluxOps**: Study storage Terraform module
- [ ] **FnCast**: Practice Cosmos DB CRUD operations

### Week 4: Security
- [ ] **FluxOps**: Analyze Key Vault integration
- [ ] **FluxOps**: Study managed identity configuration
- [ ] **FnCast**: Implement Microsoft Entra ID authentication
- [ ] **Both**: Review RBAC and access control patterns

### Week 5: Monitoring & Optimization
- [ ] **FluxOps**: Explore Application Insights integration
- [ ] **FluxOps**: Practice querying telemetry data
- [ ] **FnCast**: Implement Redis caching

### Week 6: Integration & Messaging
- [ ] **FnCast**: Practice Service Bus queues and topics
- [ ] **FnCast**: Implement Event Grid subscriptions
- [ ] **FnCast**: Configure APIM policies

---

## 📚 Hands-On Labs by Project

### FluxOps Labs

#### Lab 1: Deploy Azure Functions with Terraform
```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```
**Learning**: IaC, Function App provisioning, managed identity

#### Lab 2: Implement Blob Storage Operations
```bash
cd src/ml_pipeline
python train_model.py
```
**Learning**: Azure Storage SDK, blob upload/download, metadata

#### Lab 3: Secure Secrets with Key Vault
- Review: `infra/terraform/modules/key_vault/main.tf`
- Practice: Add new secrets, configure access policies
**Learning**: Key Vault integration, RBAC, secret rotation

#### Lab 4: Monitor with Application Insights
- Deploy FluxOps
- Generate traffic to Function endpoints
- Query logs in Azure Portal
**Learning**: Telemetry, custom metrics, log analytics

---

### FnCast Labs

#### Lab 1: Containerize and Deploy to ACR
**Learning**: Docker, container registry, image management

#### Lab 2: Implement Durable Functions
**Learning**: Orchestrator patterns, activity functions, fan-out/fan-in

#### Lab 3: Integrate Cosmos DB
**Learning**: NoSQL operations, partition keys, consistency levels

#### Lab 4: Build Event-Driven Solutions
**Learning**: Event Grid, Service Bus, event handlers

---

## 🔗 Official Microsoft Learn Resources

### Recommended Learning Paths
1. [AZ-204: Develop Azure compute solutions](https://learn.microsoft.com/training/paths/create-azure-app-service-web-apps/)
2. [AZ-204: Develop for Azure storage](https://learn.microsoft.com/training/paths/develop-solutions-that-use-blob-storage/)
3. [AZ-204: Implement Azure security](https://learn.microsoft.com/training/paths/implement-azure-security/)
4. [AZ-204: Monitor and optimize](https://learn.microsoft.com/training/paths/monitor-troubleshoot-optimize-azure-solutions/)
5. [AZ-204: Connect to Azure services](https://learn.microsoft.com/training/paths/connect-to-consume-azure-services/)

### Quick Reference Docs
- [Azure Functions Python Developer Guide](https://learn.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure Storage Blob SDK](https://learn.microsoft.com/python/api/azure-storage-blob/)
- [Azure Key Vault SDK](https://learn.microsoft.com/python/api/azure-keyvault/)
- [Application Insights API](https://learn.microsoft.com/azure/azure-monitor/app/api-custom-events-metrics)

---

## ✅ Pre-Exam Checklist

### Core Skills from FluxOps
- [ ] Can deploy Azure Functions using Terraform
- [ ] Can implement HTTP triggers with input/output bindings
- [ ] Can perform blob storage operations (upload, download, list)
- [ ] Can store and retrieve secrets from Key Vault
- [ ] Can configure managed identities for resource access
- [ ] Can integrate Application Insights with Function Apps
- [ ] Can query telemetry data in Azure Monitor

### Core Skills from FnCast
- [ ] Can containerize applications and push to ACR
- [ ] Can deploy containers to ACI/Container Apps
- [ ] Can implement Durable Functions patterns
- [ ] Can perform CRUD operations with Cosmos DB
- [ ] Can implement Service Bus queue messaging
- [ ] Can configure Event Grid subscriptions
- [ ] Can set up authentication with Microsoft Entra ID
- [ ] Can implement caching with Azure Redis

### Cross-Project Skills
- [ ] Understand IaC principles (Terraform/ARM/Bicep)
- [ ] Can implement CI/CD pipelines
- [ ] Can troubleshoot using Azure Portal diagnostics
- [ ] Can implement RBAC and least privilege access
- [ ] Can estimate and optimize Azure costs

---

## 🎓 Tips for Exam Success

### From FluxOps Project
1. **Understand the pipeline**: Study how CI/CD automates infrastructure deployment
2. **Know the security model**: Key Vault + Managed Identity is critical
3. **Practice Terraform**: IaC is increasingly important in Azure development
4. **Master blob operations**: Common in real-world scenarios

### From FnCast Project
1. **Container fundamentals**: Know when to use Functions vs Containers
2. **Message vs Event patterns**: Understand Service Bus vs Event Grid
3. **Durable Functions**: Complex but powerful orchestration patterns
4. **Cosmos DB partitioning**: Critical for scalability

### General Exam Tips
- ✅ Focus on **hands-on practice** over memorization
- ✅ Understand **when to use each Azure service** (scenarios)
- ✅ Know **pricing tiers** and **service limits**
- ✅ Practice **troubleshooting** using Portal diagnostics
- ✅ Review **best practices** for security and performance

---

## 📞 Additional Resources

### Community
- [Microsoft Q&A - Azure](https://learn.microsoft.com/answers/tags/133/azure)
- [Azure Developer Community](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/bg-p/AzureDevCommunityBlog)
- [r/AZURE Reddit](https://reddit.com/r/AZURE)

### Practice Exams
- Microsoft Official Practice Assessment
- Pluralsight AZ-204 Practice Tests
- Udemy Practice Exams

### Code Samples
- [Azure Samples GitHub](https://github.com/Azure-Samples)
- [Azure Functions Samples](https://github.com/Azure/azure-functions-python-samples)

---

**Last Updated**: January 2026  
**Exam Version**: AZ-204 (current as of 2026)  
**Projects**: FluxOps v1.0, FnCast v1.0

---

**Good luck with your AZ-204 certification! 🚀**
