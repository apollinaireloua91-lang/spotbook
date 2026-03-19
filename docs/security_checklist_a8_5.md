# Checklist sécurité A8.5 (avant P9)

- [x] flutter analyze = 0
- [x] Rate limiting actif (login/otp/payment)
- [x] Validation d'inputs ajoutée sur fonctions critiques
- [x] Audit logs table + actions clés
- [x] Headers CORS/sécurité ajoutés sur fonctions critiques
- [x] Chiffrement tokens OAuth côté DB (pgsodium)
- [x] Policies Storage durcies (`kyc-documents` privé)
- [x] Refresh session implémenté côté Flutter
- [x] Script de vérification RLS ajouté (`supabase/rls_security_checks.sql`)
- [x] Recherche clés sensibles côté Flutter effectuée
- [ ] Tests TestSprite exécutés au vert (nécessite clé API locale)
- [ ] Paramètres JWT Dashboard appliqués (nécessite accès Dashboard)
