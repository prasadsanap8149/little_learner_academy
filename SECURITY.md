# Firebase Security Rules - Little Learners Academy

This document outlines the comprehensive security implementation for the Little Learners Academy Firebase backend, including Firestore and Storage security rules, admin access controls, and audit mechanisms.

## 🔐 Security Overview

The security system implements a multi-layered approach:

1. **Role-Based Access Control (RBAC)** - Different admin roles with specific privileges
2. **Firestore Security Rules** - Database-level security for all collections
3. **Storage Security Rules** - File storage security for assets and user content
4. **Admin Security Utils** - Enhanced security monitoring and audit trails
5. **Rate Limiting** - Protection against abuse and excessive API calls

## 👥 Admin Roles & Privileges

### Admin Roles

| Role | Description | Email Pattern |
|------|-------------|---------------|
| **Super Admin** | Full system access | `admin@littlelearnersacademy.com`, `sanapprasad2021@gmail.com` |
| **Content Manager** | Game and educational content management | `content@littlelearnersacademy.com` |
| **Support** | User support and basic analytics | `support@littlelearnersacademy.com` |

### Admin Privileges

| Privilege | Super Admin | Content Manager | Support |
|-----------|-------------|-----------------|---------|
| User Management | ✅ | ❌ | ✅ |
| Content Management | ✅ | ✅ | ❌ |
| Game Management | ✅ | ✅ | ❌ |
| Analytics | ✅ | ✅ | ✅ |
| System Settings | ✅ | ❌ | ❌ |
| Subscription Management | ✅ | ❌ | ✅ |

## 📊 Firestore Collections Security

### User Collections

| Collection | Read | Write | Admin Read | Admin Write |
|------------|------|-------|------------|-------------|
| `users` | Owner only | Owner only | All admins | Support+ |
| `user_profiles` | Owner only | Owner only | All admins | Support+ |
| `player_progress` | Owner only | Owner only | All admins | Support+ |
| `user_achievements` | Owner only | Owner only | All admins | Support+ |
| `user_subscriptions` | Owner only | Owner only | All admins | Support+ |

### Game & Content Collections

| Collection | Read | Write | Admin Read | Admin Write |
|------------|------|-------|------------|-------------|
| `games` | All users | ❌ | All admins | Content Manager+ |
| `game_levels` | All users | ❌ | All admins | Content Manager+ |
| `content` | All users | ❌ | All admins | Content Manager+ |
| `achievements` | All users | ❌ | All admins | Content Manager+ |

### System Collections

| Collection | Read | Write | Admin Read | Admin Write |
|------------|------|-------|------------|-------------|
| `admin_users` | ❌ | ❌ | All admins | All admins |
| `app_settings` | All users | ❌ | All admins | Super Admin only |
| `subscription_plans` | All users | ❌ | All admins | Super Admin only |
| `analytics` | ❌ | Users (create) | All admins | Super Admin only |

## 🗂️ Storage Security Rules

### User Content

- **Profile Pictures**: Read by all, write by owner or admin
- **User Generated Content**: Read/write by owner, read by admin
- **Temporary Files**: Auto-cleanup after 24 hours

### System Assets

- **Game Assets**: Read by all users, write by content managers
- **App Assets**: Read by all users, write by content managers
- **Public Assets**: Read by all, write by content managers
- **Backups**: Super admin only

## 🔍 Security Monitoring

### Audit Trail

All admin actions are logged with:
- Admin ID and email
- Action performed
- Target resource
- Before/after states
- Timestamp and session ID
- Reason (when provided)

### Security Logs

Detailed security events including:
- Access granted/denied events
- Rate limiting violations
- Emergency lockdown actions
- Data export requests

### Rate Limiting

Basic rate limiting implemented for admin actions:
- Default: 100 actions per minute per admin
- Configurable per action type
- Automatic cleanup of old timestamps

## 🚀 Deployment

### Prerequisites

1. **Firebase CLI**: Install with `npm install -g firebase-tools`
2. **Firebase Project**: Ensure project is initialized and selected
3. **Authentication**: Login with `firebase login`

### Deploy Security Rules

Run the deployment script:

```bash
./deploy_security_rules.sh
```

Or deploy manually:

```bash
# Deploy all rules
firebase deploy --only firestore:rules,storage:rules,firestore:indexes

# Deploy individually
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
firebase deploy --only firestore:indexes
```

### Validation

Test your rules:

```bash
# Test Firestore rules
firebase firestore:rules:test firestore.rules

# Test Storage rules
firebase storage:rules:test storage.rules
```

## 🛡️ Security Best Practices

### For Developers

1. **Always validate admin privileges** before performing sensitive operations
2. **Use audit logging** for all admin actions
3. **Implement rate limiting** for API endpoints
4. **Validate input data** before database operations
5. **Use secure random tokens** for sensitive operations

### For Admins

1. **Use strong passwords** and enable 2FA
2. **Regularly review audit logs** for suspicious activity
3. **Follow principle of least privilege** when assigning roles
4. **Monitor rate limiting alerts** for potential abuse
5. **Keep admin email list updated** in the code

## 🔧 Configuration

### Adding New Admin Users

1. Update the `adminEmails` map in `AdminService`:

```dart
static const Map<String, AdminRole> adminEmails = {
  'admin@littlelearnersacademy.com': AdminRole.superAdmin,
  'sanapprasad2021@gmail.com': AdminRole.superAdmin,
  'content@littlelearnersacademy.com': AdminRole.contentManager,
  'support@littlelearnersacademy.com': AdminRole.support,
  'newemail@littlelearnersacademy.com': AdminRole.support, // Add here
};
```

2. Update Firestore security rules if new role patterns are needed
3. Deploy updated rules and restart the application

### Customizing Privileges

Modify the `hasAdminPrivilege` method in `AdminService` to adjust role permissions:

```dart
static bool hasAdminPrivilege(AdminPrivilege privilege, [String? email]) {
  final role = getAdminRole(email);
  if (role == null) return false;

  switch (privilege) {
    case AdminPrivilege.newPrivilege:
      return role == AdminRole.superAdmin; // Customize as needed
    // ... other cases
  }
}
```

## 🚨 Emergency Procedures

### Emergency Lockdown

If security is compromised:

1. Call `AdminSecurityUtils.emergencyLockdown()`
2. This logs the event and can disable admin access
3. Only super admins can initiate lockdown
4. Review security logs immediately

### Data Breach Response

1. **Immediate**: Revoke compromised admin access
2. **Short-term**: Review audit logs for affected data
3. **Long-term**: Update security rules and redeploy

## 📈 Monitoring & Alerts

### Firebase Console Monitoring

1. **Firestore**: Monitor read/write patterns and rule violations
2. **Storage**: Track unusual upload/download patterns
3. **Authentication**: Review sign-in logs and failed attempts

### Custom Monitoring

The app logs security events that can be monitored:
- Failed admin privilege checks
- Rate limiting violations
- Unusual access patterns
- Emergency actions

## 🔄 Updates & Maintenance

### Regular Tasks

1. **Weekly**: Review admin audit logs
2. **Monthly**: Update admin email list if needed
3. **Quarterly**: Review and update security rules
4. **As needed**: Add new privileges and collections

### Version Control

All security rules are version controlled:
- `firestore.rules` - Database security rules
- `storage.rules` - Storage security rules
- `firestore.indexes.json` - Database indexes
- `firebase.json` - Firebase configuration

Track changes and test thoroughly before deployment.

## 📚 Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Storage Security](https://firebase.google.com/docs/storage/security)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin)

---

**Note**: This security implementation provides a robust foundation but should be regularly reviewed and updated based on your specific requirements and evolving security best practices.
