#!/bin/bash
# reset-all.sh - Clean up all practice resources
echo "🧹 Cleaning up ALL practice resources..."

NAMESPACES=(
    "autoscale" "sound-repeater" "relative-fawn" "spline-reticulator"
    "priority" "argocd" "mariadb" "nginx-static" "cert-manager"
    "frontend" "backend"
)

for cluster in cluster1 cluster2 cluster3; do
    echo ""
    echo "Cleaning: $cluster"
    kubectl config use-context "$cluster" > /dev/null 2>&1
    for ns in "${NAMESPACES[@]}"; do
        kubectl delete namespace "$ns" --ignore-not-found --timeout=30s 2>/dev/null
    done
    kubectl delete deployment resource-hog --ignore-not-found 2>/dev/null
    kubectl delete pod load-generator --ignore-not-found 2>/dev/null
done

echo ""
echo "✅ Cleanup complete!"
