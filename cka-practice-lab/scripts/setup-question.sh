#!/bin/bash
# setup-question.sh - Setup individual CKA practice question for KodeKloud
# Usage: ./setup-question.sh <question-number>

set -e  # Exit on any error

# Display help if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: ./setup-question.sh <question-number>"
    echo ""
    echo "Available questions:"
    for config in configs/q*.config; do
        NUM=$(basename "$config" | grep -o '[0-9]\+' | head -1)
        if [ -n "$NUM" ]; then
            # Extract title from config file
            TITLE=$(grep "^QUESTION_TITLE=" "$config" | cut -d'"' -f2 2>/dev/null || echo "Question $NUM")
            echo "  $NUM: $TITLE"
        fi
    done | sort -n
    exit 1
fi

QUESTION_NUM=$1

# Find the config file (handles both q1-hpa.config and q1.config formats)
CONFIG_FILE="configs/q${QUESTION_NUM}-*.config"
CONFIG_PATH=$(ls $CONFIG_FILE 2>/dev/null | head -1)

if [ -z "$CONFIG_PATH" ]; then
    echo "❌ Error: Configuration file for Question $QUESTION_NUM not found!"
    echo ""
    echo "Available configuration files:"
    ls configs/q*.config 2>/dev/null | sed 's/configs\///' || echo "  No config files found in configs/"
    echo ""
    echo "Make sure you have created the config file: configs/q${QUESTION_NUM}-*.config"
    exit 1
fi

# Clear screen for better visibility
clear
echo "========================================"
echo "🚀 CKA Practice Question Setup"
echo "========================================"

# Load the configuration
source "$CONFIG_PATH"

echo "📋 Question: $QUESTION_TITLE"
echo "🏷️  Number:   $QUESTION_NUM"
echo "🏢 Cluster:  $CLUSTER_CONTEXT"
echo "📁 Namespace: ${NAMESPACE:-default}"
echo "========================================"
echo ""

# Step 1: Switch kubectl context
echo "🔧 Step 1/4: Switching to cluster context..."
if ! kubectl config use-context "$CLUSTER_CONTEXT" 2>/dev/null; then
    echo "❌ Failed to switch to context: $CLUSTER_CONTEXT"
    echo ""
    echo "Available contexts:"
    kubectl config get-contexts
    echo ""
    echo "Please check your cluster access and try again."
    exit 1
fi
echo "✅ Connected to: $CLUSTER_CONTEXT"

# Step 2: Create namespace if specified
if [ -n "$NAMESPACE" ] && [ "$NAMESPACE" != "default" ]; then
    echo "📁 Step 2/4: Creating namespace..."
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo "⚠️  Namespace '$NAMESPACE' already exists (skipping creation)"
    else
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        echo "✅ Namespace '$NAMESPACE' created"
    fi
else
    echo "📁 Step 2/4: Using default namespace (skipping namespace creation)"
fi

# Step 3: Apply manifests if specified
if [ -n "$MANIFESTS" ]; then
    echo "📄 Step 3/4: Applying manifests..."
    MANIFEST_COUNT=0
    APPLIED_COUNT=0
    
    for manifest_pattern in $MANIFESTS; do
        # Expand glob patterns
        for manifest in $manifest_pattern; do
            MANIFEST_COUNT=$((MANIFEST_COUNT + 1))
            
            if [ -f "$manifest" ]; then
                echo "  📄 Applying: $(basename "$manifest")"
                if kubectl apply -f "$manifest" 2>/dev/null; then
                    APPLIED_COUNT=$((APPLIED_COUNT + 1))
                else
                    echo "  ⚠️  Warning: Failed to apply $manifest"
                fi
            else
                echo "  ⚠️  Warning: Manifest not found: $manifest"
            fi
        done
    done
    
    if [ $APPLIED_COUNT -eq 0 ] && [ $MANIFEST_COUNT -gt 0 ]; then
        echo "⚠️  No manifests were applied (check if files exist)"
    else
        echo "✅ Applied $APPLIED_COUNT of $MANIFEST_COUNT manifest(s)"
    fi
else
    echo "📄 Step 3/4: No manifests to apply (skipping)"
fi

# Step 4: Run additional setup if defined
if [ -n "$ADDITIONAL_SETUP" ]; then
    echo "⚙️  Step 4/4: Running additional setup..."
    echo ""
    eval "$ADDITIONAL_SETUP"
else
    echo "⚙️  Step 4/4: No additional setup required (skipping)"
fi

echo ""
echo "========================================"
echo "🎉 SETUP COMPLETE!"
echo "========================================"
echo ""
echo "📋 Summary for Question $QUESTION_NUM:"
echo "   Title:    $QUESTION_TITLE"
echo "   Cluster:  $CLUSTER_CONTEXT"
echo "   Namespace: ${NAMESPACE:-default}"
echo ""

# Show verification commands
echo "🔍 Verification Commands:"
if [ -n "$NAMESPACE" ] && [ "$NAMESPACE" != "default" ]; then
    echo "   kubectl --context=$CLUSTER_CONTEXT get all -n $NAMESPACE"
    echo "   kubectl --context=$CLUSTER_CONTEXT get pods -n $NAMESPACE"
    echo "   kubectl --context=$CLUSTER_CONTEXT describe pods -n $NAMESPACE"
else
    echo "   kubectl --context=$CLUSTER_CONTEXT get all"
    echo "   kubectl --context=$CLUSTER_CONTEXT get pods"
fi
echo ""

# Special instructions for different question types
case $QUESTION_NUM in
    4)
        echo "📝 Special Instructions for Q4 (StorageClass):"
        echo "   StorageClass is a CLUSTER-SCOPED resource (no namespace)"
        echo "   Check existing: kubectl get storageclass"
        echo "   Create new: kubectl create -f your-storageclass.yaml"
        ;;
    7)
        echo "📝 Special Instructions for Q7 (ArgoCD Helm):"
        echo "   Requires Helm: helm version"
        echo "   Add repo: helm repo add argo https://argoproj.github.io/argo-helm"
        echo "   Install: helm install argocd argo/argo-cd --version 5.5.22 -n argocd --set crds.install=false"
        ;;
    11)
        echo "📝 Special Instructions for Q11 (cert-manager CRD):"
        echo "   Task 1: kubectl get crd | grep cert-manager > ~/resources.yaml"
        echo "   Task 2: kubectl explain certificate.spec.subject > ~/subject.yaml"
        ;;
    13)
        echo "📝 Special Instructions for Q13 (Calico CNI):"
        echo "   ⚠️  WARNING: Installing CNI may disrupt cluster networking!"
        echo "   Check Pod CIDR: kubectl cluster-info dump | grep -i cluster-cidr"
        echo "   Install Calico: kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml"
        ;;
    15|16)
        echo "📝 Special Instructions for Q$QUESTION_NUM:"
        if [ "$QUESTION_NUM" = "15" ]; then
            echo "   🔐 Requires SSH to control plane: ssh cluster3-controlplane"
            echo "   Check: sudo systemctl status etcd"
            echo "   Check: sudo journalctl -u kube-apiserver"
        else
            echo "   🔐 Requires SSH to worker node: ssh cluster1-node01"
            echo "   Install: sudo dpkg -i ~/cri-dockerd*.deb"
            echo "   Configure: Edit /etc/sysctl.conf and add network parameters"
        fi
        ;;
esac

echo ""
echo "📚 Practice Instructions:"
echo "   1. Use your PDF solution as reference"
echo "   2. Replace 'ssh cka0000XX' with 'kubectl config use-context $CLUSTER_CONTEXT'"
echo "   3. Add '--context=$CLUSTER_CONTEXT' to kubectl commands if needed"
echo ""

# Quick status check
echo "📊 Quick Status Check:"
if [ -n "$NAMESPACE" ] && [ "$NAMESPACE" != "default" ]; then
    kubectl --context="$CLUSTER_CONTEXT" get pods -n "$NAMESPACE" 2>/dev/null | head -10 || echo "   Unable to get pod status"
else
    kubectl --context="$CLUSTER_CONTEXT" get pods 2>/dev/null | head -10 || echo "   Unable to get pod status"
fi

echo ""
echo "🧹 To clean up: ./reset-all.sh"
echo "🏠 To return to base: kubectl config use-context cluster1"
echo "========================================"
