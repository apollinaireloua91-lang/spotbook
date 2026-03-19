# JWT et session sécurisée (A8.5)

## Dashboard Supabase (manuel)

- JWT expiry: `3600` secondes
- Refresh token rotation: `enabled`
- Refresh token reuse interval: `10` secondes

## Flutter (implémenté)

- `AuthRepository.signInWithEmail()` gère le rate-limit login.
- `AuthRepository.resetPassword()` gère le rate-limit OTP.
- `AuthRepository.refreshSession()` est ajouté.
- En cas de token expiré, l'app tente un refresh puis force la reconnexion si nécessaire.
