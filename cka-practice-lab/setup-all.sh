#!/bin/bash
# setup-all.sh - Set up all CKA practice questions
echo "🚀 Setting up ALL CKA Practice Questions"
echo "========================================"

chmod +x scripts/*.sh 2>/dev/null
chmod +x setup-question.sh

QUESTIONS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14)

for q in "${QUESTIONS[@]}"; do
    echo ""
    echo "▶️  Setting up Question $q..."
    echo "----------------------------------------"
    ./setup-question.sh "$q" 2>&1 | grep -E "(Setting up|Applying|Setup complete)"
    sleep 2
done

echo ""
echo "========================================"
echo "🎉 Setup Complete!"
echo "Questions 1-14: Automated setup"
echo "Question 15: SSH to cluster3-controlplane"
echo "Question 16: SSH to cluster1-node01"
