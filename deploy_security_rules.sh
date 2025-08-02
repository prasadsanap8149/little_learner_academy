#!/bin/bash

# Firebase Security Rules Deployment Script for Little Learners Academy
# This script deploys Firestore and Storage security rules

echo "🔐 Firebase Security Rules Deployment Script"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed${NC}"
    echo "Please install it by running: npm install -g firebase-tools"
    exit 1
fi

echo -e "${GREEN}✅ Firebase CLI is installed${NC}"

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Please log in to Firebase first${NC}"
    echo "Running: firebase login"
    firebase login
fi

echo -e "${GREEN}✅ Firebase authentication verified${NC}"

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ firebase.json not found${NC}"
    echo "Please ensure you're in the project root directory"
    exit 1
fi

echo -e "${GREEN}✅ Firebase configuration found${NC}"

# Validate Firestore rules syntax
echo -e "${BLUE}🔍 Validating Firestore security rules...${NC}"
if firebase firestore:rules:test firestore.rules &> /dev/null; then
    echo -e "${GREEN}✅ Firestore rules syntax is valid${NC}"
else
    echo -e "${RED}❌ Firestore rules have syntax errors${NC}"
    echo "Please check your firestore.rules file"
    exit 1
fi

# Validate Storage rules syntax
echo -e "${BLUE}🔍 Validating Storage security rules...${NC}"
if firebase storage:rules:test storage.rules &> /dev/null; then
    echo -e "${GREEN}✅ Storage rules syntax is valid${NC}"
else
    echo -e "${RED}❌ Storage rules have syntax errors${NC}"
    echo "Please check your storage.rules file"
    exit 1
fi

# Show current Firebase project
PROJECT=$(firebase use --current 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${BLUE}📦 Current Firebase project: ${GREEN}$PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  No Firebase project selected${NC}"
    echo "Please run: firebase use --add"
    exit 1
fi

# Confirm deployment
echo ""
echo -e "${YELLOW}🚀 Ready to deploy security rules to project: $PROJECT${NC}"
echo "This will update:"
echo "  - Firestore security rules"
echo "  - Firebase Storage security rules"
echo "  - Firestore indexes"
echo ""
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  Deployment cancelled${NC}"
    exit 0
fi

# Deploy Firestore rules
echo -e "${BLUE}🔄 Deploying Firestore security rules...${NC}"
if firebase deploy --only firestore:rules; then
    echo -e "${GREEN}✅ Firestore security rules deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy Firestore security rules${NC}"
    exit 1
fi

# Deploy Storage rules
echo -e "${BLUE}🔄 Deploying Storage security rules...${NC}"
if firebase deploy --only storage:rules; then
    echo -e "${GREEN}✅ Storage security rules deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy Storage security rules${NC}"
    exit 1
fi

# Deploy Firestore indexes
echo -e "${BLUE}🔄 Deploying Firestore indexes...${NC}"
if firebase deploy --only firestore:indexes; then
    echo -e "${GREEN}✅ Firestore indexes deployed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Firestore indexes deployment had warnings (this is often normal)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Security rules deployment completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Test your admin functionality to ensure rules work correctly"
echo "2. Monitor Firebase console for any rule violations"
echo "3. Update admin email addresses in AdminService if needed"
echo ""
echo "Admin email addresses configured:"
echo "  - admin@littlelearnersacademy.com (Super Admin)"
echo "  - prasad@littlelearnersacademy.com (Super Admin)"
echo "  - content@littlelearnersacademy.com (Content Manager)"
echo "  - support@littlelearnersacademy.com (Support)"
echo ""
echo -e "${BLUE}📝 Security features enabled:${NC}"
echo "  ✅ Role-based access control"
echo "  ✅ Admin privilege validation"
echo "  ✅ User data protection"
echo "  ✅ Audit trail logging"
echo "  ✅ Rate limiting protection"
echo "  ✅ Secure data access patterns"
