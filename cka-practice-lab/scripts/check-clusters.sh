#!/bin/bash
echo "🔍 Checking KodeKloud Cluster Access"

for cluster in cluster1 cluster2 cluster3; do
    echo ""
    echo "Cluster: $cluster"
    if kubectl config use-context "$cluster" >/dev/null 2>&1; then
        NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
        echo "✅ Connected - Nodes: $NODES"
    else
        echo "❌ Failed to connect"
    fi
done

echo ""
kubectl config get-contexts
