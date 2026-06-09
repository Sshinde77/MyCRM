# mycrm

A new Flutter project.

## Login API Integration

The login screen now calls the backend endpoint defined in `ApiConstants.login`.

Base URL:

`https://api.example.com/v1`

Endpoint:

`POST /login`

Request body:

```json
{
  "email": "user@example.com",
  "password": "your-password"
}
```

Supported response fields in the app:

```json
{
  "message": "Login successful",
  "token": "jwt-or-access-token",
  "user": {
    "id": "1",
    "name": "John Doe",
    "email": "user@example.com",
    "phone": "+919999999999",
    "role": "admin",
    "profile_picture": "https://example.com/profile.jpg"
  }
}
```

The app also tolerates common variants such as `access_token`, `accessToken`, `_id`, `user_id`, `full_name`, `username`, `mobile`, and flat user fields returned without a nested `user` object.

Persisted auth data:

- `auth_token` stores the returned token when present
- `current_user` stores the authenticated user JSON in shared preferences

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
