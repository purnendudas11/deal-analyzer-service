// Configuration
const CONFIG = {
    apiEndpoint: localStorage.getItem('apiEndpoint') || '',
    s3Bucket: localStorage.getItem('s3Bucket') || '',
    awsRegion: localStorage.getItem('awsRegion') || 'us-east-1',
};

let uploadedFileContent = null;
let s3FileKey = null;

// DOM Elements
const fileInput = document.getElementById('fileInput');
const fileLabel = document.querySelector('.file-label');
const fileNameDisplay = document.getElementById('fileNameDisplay');
const fileInfo = document.getElementById('fileInfo');
const fileName = document.getElementById('fileName');
const filePreview = document.getElementById('filePreview');
const uploadBtn = document.getElementById('uploadBtn');
const uploadStatus = document.getElementById('uploadStatus');
const analysisSection = document.getElementById('analysisSection');
const explainBtn = document.getElementById('explainBtn');
const loadingIndicator = document.getElementById('loadingIndicator');
const explanationOutput = document.getElementById('explanationOutput');
const detailsSection = document.getElementById('detailsSection');
const dealDetails = document.getElementById('dealDetails');

const apiEndpointInput = document.getElementById('apiEndpoint');
const s3BucketInput = document.getElementById('s3Bucket');
const awsRegionSelect = document.getElementById('awsRegion');
const saveConfigBtn = document.getElementById('saveConfigBtn');
const configStatus = document.getElementById('configStatus');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
    loadConfiguration();
});

function setupEventListeners() {
    // File input
    fileInput.addEventListener('change', handleFileSelect);
    fileLabel.addEventListener('dragover', handleDragOver);
    fileLabel.addEventListener('dragleave', handleDragLeave);
    fileLabel.addEventListener('drop', handleDrop);

    // Upload button
    uploadBtn.addEventListener('click', handleUpload);

    // Explain button
    explainBtn.addEventListener('click', handleExplain);

    // Configuration
    saveConfigBtn.addEventListener('click', saveConfiguration);

    // Load saved config values
    apiEndpointInput.value = CONFIG.apiEndpoint;
    s3BucketInput.value = CONFIG.s3Bucket;
    awsRegionSelect.value = CONFIG.awsRegion;
}

// File handling
function handleFileSelect(event) {
    const file = event.target.files[0];
    if (file) {
        processFile(file);
    }
}

function handleDragOver(event) {
    event.preventDefault();
    event.stopPropagation();
    fileLabel.style.backgroundColor = '#e3f2fd';
    fileLabel.style.borderColor = 'var(--primary-color)';
}

function handleDragLeave(event) {
    event.preventDefault();
    event.stopPropagation();
    fileLabel.style.backgroundColor = 'var(--light-bg)';
    fileLabel.style.borderColor = 'var(--secondary-color)';
}

function handleDrop(event) {
    event.preventDefault();
    event.stopPropagation();
    fileLabel.style.backgroundColor = 'var(--light-bg)';
    fileLabel.style.borderColor = 'var(--secondary-color)';

    const files = event.dataTransfer.files;
    if (files.length > 0) {
        const file = files[0];
        if (file.type === 'application/json') {
            fileInput.files = files;
            processFile(file);
        } else {
            showError('Please upload a JSON file');
        }
    }
}

function processFile(file) {
    const reader = new FileReader();
    reader.onload = function(e) {
        try {
            uploadedFileContent = JSON.parse(e.target.result);
            
            // Update UI
            fileName.textContent = file.name;
            filePreview.textContent = JSON.stringify(uploadedFileContent, null, 2);
            fileInfo.style.display = 'block';
            fileNameDisplay.textContent = `✓ ${file.name}`;
            uploadBtn.style.display = 'block';
            
            // Display deal details
            displayDealDetails(uploadedFileContent);
            
            clearStatus(uploadStatus);
            showSuccess(uploadStatus, 'JSON file loaded successfully');
        } catch (error) {
            showError(uploadStatus, `Invalid JSON: ${error.message}`);
            resetFileInput();
        }
    };
    reader.readAsText(file);
}

function displayDealDetails(dealData) {
    if (!dealData.deal) return;

    detailsSection.style.display = 'block';
    dealDetails.innerHTML = '';

    const deal = dealData.deal;
    const details = [];

    // Extract key details
    if (deal.parties && deal.parties.length > 0) {
        const buyer = deal.parties[0];
        details.push({
            label: 'Buyer',
            value: `${buyer.personName?.givenName} ${buyer.personName?.familyName}`
        });
    }

    if (deal.vehicle) {
        const vehicle = deal.vehicle;
        details.push({
            label: 'Vehicle',
            value: `${vehicle.modelYear} ${vehicle.make} ${vehicle.model}`
        });
        details.push({
            label: 'VIN',
            value: vehicle.vin
        });
    }

    if (deal.financeTerms) {
        const terms = deal.financeTerms;
        details.push({
            label: 'Sale Price',
            value: formatCurrency(terms.salePrice)
        });
        details.push({
            label: 'Down Payment',
            value: formatCurrency(terms.downPayment)
        });
        details.push({
            label: 'Term',
            value: `${terms.termMonths} months`
        });
        details.push({
            label: 'APR',
            value: `${terms.apr}%`
        });
        details.push({
            label: 'Monthly Payment',
            value: formatCurrency(terms.monthlyPayment)
        });
    }

    details.forEach(detail => {
        const detailItem = document.createElement('div');
        detailItem.className = 'detail-item';
        detailItem.innerHTML = `
            <strong>${detail.label}</strong>
            <span>${detail.value}</span>
        `;
        dealDetails.appendChild(detailItem);
    });
}

// Upload to S3
async function handleUpload() {
    if (!uploadedFileContent) {
        showError(uploadStatus, 'Please select a file first');
        return;
    }

    if (!CONFIG.s3Bucket) {
        showError(uploadStatus, 'Please configure S3 bucket name first');
        return;
    }

    uploadBtn.disabled = true;
    showInfo(uploadStatus, 'Uploading to S3...');

    try {
        // Generate file key with timestamp
        s3FileKey = `deals/${Date.now()}-deal-structure.json`;

        // Create presigned URL request
        const response = await fetch(`${CONFIG.apiEndpoint}/presigned-url`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                fileName: s3FileKey,
                contentType: 'application/json'
            })
        });

        if (!response.ok) {
            throw new Error(`API error: ${response.statusText}`);
        }

        const { presignedUrl, fileKey } = await response.json();
        s3FileKey = fileKey;

        // Upload file to S3
        const uploadResponse = await fetch(presignedUrl, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(uploadedFileContent)
        });

        if (!uploadResponse.ok) {
            throw new Error('Failed to upload to S3');
        }

        showSuccess(uploadStatus, `File uploaded successfully! Key: ${s3FileKey}`);
        analysisSection.style.display = 'block';
        explainBtn.disabled = false;

    } catch (error) {
        showError(uploadStatus, `Upload failed: ${error.message}`);
        explainBtn.disabled = true;
    } finally {
        uploadBtn.disabled = false;
    }
}

// Explain deal with Bedrock
async function handleExplain() {
    if (!s3FileKey) {
        showError('uploadStatus', 'Please upload the deal structure first');
        return;
    }

    if (!CONFIG.apiEndpoint) {
        showError('uploadStatus', 'Please configure API endpoint first');
        return;
    }

    explainBtn.disabled = true;
    loadingIndicator.style.display = 'flex';
    explanationOutput.classList.remove('show');

    try {
        const response = await fetch(`${CONFIG.apiEndpoint}/analyze-deal`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                s3Key: s3FileKey,
                s3Bucket: CONFIG.s3Bucket,
                region: CONFIG.awsRegion
            })
        });

        if (!response.ok) {
            throw new Error(`API error: ${response.statusText}`);
        }

        const data = await response.json();
        displayExplanation(data.explanation);

    } catch (error) {
        showError('uploadStatus', `Analysis failed: ${error.message}`);
        explanationOutput.innerHTML = '';
    } finally {
        loadingIndicator.style.display = 'none';
        explainBtn.disabled = false;
    }
}

function displayExplanation(explanation) {
    explanationOutput.innerHTML = explanation;
    explanationOutput.classList.add('show');
    
    // Scroll to explanation
    setTimeout(() => {
        explanationOutput.scrollIntoView({ behavior: 'smooth' });
    }, 300);
}

// Configuration management
function saveConfiguration() {
    const apiEndpoint = apiEndpointInput.value.trim();
    const s3Bucket = s3BucketInput.value.trim();
    const awsRegion = awsRegionSelect.value;

    if (!apiEndpoint || !s3Bucket) {
        showError(configStatus, 'Please fill in all configuration fields');
        return;
    }

    // Validate API endpoint format
    if (!apiEndpoint.includes('execute-api') && !apiEndpoint.startsWith('http')) {
        showError(configStatus, 'Invalid API endpoint format');
        return;
    }

    CONFIG.apiEndpoint = apiEndpoint;
    CONFIG.s3Bucket = s3Bucket;
    CONFIG.awsRegion = awsRegion;

    localStorage.setItem('apiEndpoint', apiEndpoint);
    localStorage.setItem('s3Bucket', s3Bucket);
    localStorage.setItem('awsRegion', awsRegion);

    showSuccess(configStatus, 'Configuration saved successfully!');
}

function loadConfiguration() {
    apiEndpointInput.value = CONFIG.apiEndpoint;
    s3BucketInput.value = CONFIG.s3Bucket;
    awsRegionSelect.value = CONFIG.awsRegion;
}

// Utility functions
function resetFileInput() {
    fileInput.value = '';
    fileInfo.style.display = 'none';
    uploadBtn.style.display = 'none';
    fileNameDisplay.textContent = 'Click to select or drag & drop JSON file';
    uploadedFileContent = null;
    s3FileKey = null;
}

function formatCurrency(value) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2
    }).format(value);
}

function showSuccess(element, message) {
    element.textContent = message;
    element.className = 'status-message success';
}

function showError(element, message) {
    if (typeof element === 'string') {
        element = document.getElementById(element);
    }
    element.textContent = message;
    element.className = 'status-message error';
}

function showInfo(element, message) {
    if (typeof element === 'string') {
        element = document.getElementById(element);
    }
    element.textContent = message;
    element.className = 'status-message info';
}

function clearStatus(element) {
    element.textContent = '';
    element.className = 'status-message';
}
