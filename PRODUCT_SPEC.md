# SPOTBOOK — Product Specification for Front-End Testing

> **Version:** 1.0  
> **Last updated:** 2026-03-19  
> **Platform:** Flutter (iOS + Android)  
> **Architecture:** Clean Architecture + Riverpod + GoRouter + Supabase

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [User Roles](#2-user-roles)
3. [Authentication & Onboarding Flows](#3-authentication--onboarding-flows)
4. [Navigation Structure](#4-navigation-structure)
5. [Screen-by-Screen Specifications](#5-screen-by-screen-specifications)
6. [Shared Widgets](#6-shared-widgets)
7. [Data Models](#7-data-models)
8. [Business Rules & Validation](#8-business-rules--validation)
9. [Design System](#9-design-system)
10. [Error States & Edge Cases](#10-error-states--edge-cases)
11. [Dependencies](#11-dependencies)
12. [Database Schema (26 tables)](#12-database-schema-26-tables)
13. [Edge Functions (Backend)](#13-edge-functions-backend)
14. [Test Checklist](#14-test-checklist)

---

## 1. Project Overview

**Spotbook** is a premium mobile super-app combining:
- **TikTok-style vertical video feed** — only professionals can upload videos showcasing their services
- **Service booking with deposit** — clients book appointments with pros and pay a Stripe deposit
- **Event ticketing with QR** — buy tickets, receive a QR code, scan at entry

**Markets:** Canada, France, USA, Ivory Coast  
**Languages:** French (default) + English  
**Design:** Strict black & white — no decorative colors

---

## 2. User Roles

### 2.1 Client
- Browse video feed
- Discover professionals
- Book appointments (with Stripe deposit)
- Buy event tickets
- Chat with pros (after booking)
- Leave reviews
- Manage favorites, notifications, settings

**Client CANNOT:** upload videos, access dashboard, create events, scan QR codes

### 2.2 Pro (Professional)
- Upload service videos (max 60s, moderated)
- Manage availability and bookings
- Create events and ticket types
- Scan QR tickets at entry
- Access dashboard with stats (bookings, revenue, rating)
- Link social accounts (Instagram, TikTok, YouTube)
- Manage promo codes
- Subscribe to Pro Premium (29 CAD/month)

**Pro CANNOT:** use client-specific screens (client profile tabs, client booking view)

### 2.3 Role Enforcement
- A user can be either Client OR Pro — never both simultaneously
- Role is stored in `users.role` column (`'client'` | `'pro'`)
- Role is selected during onboarding (`AccountTypeSelectionScreen`)
- Client and Pro interfaces never share a screen

---

## 3. Authentication & Onboarding Flows

### 3.1 App Launch Sequence

```
SplashScreen (logo + fade animation, 2s)
  ├─ No session → /onboarding
  ├─ Session + role='client' → /client/feed
  ├─ Session + role='pro' → /pro/dashboard
  └─ Session + no role → /onboarding
```

### 3.2 Onboarding (First Launch Only)

| Step | Screen | Content |
|------|--------|---------|
| 1 | OnboardingScreen (slide 1) | "Discover" — browse local pros |
| 2 | OnboardingScreen (slide 2) | "Book & Attend" — appointments and events |
| 3 | OnboardingScreen (slide 3) | "Create & Earn" — for professionals |

**Interactions:** Swipe between slides, "Next" button, "Skip" link, "Get Started" on last slide  
**Navigation:** "Get Started" → `/account-type`, "Skip" or sign-in link → `/login`

### 3.3 Account Type Selection

| Element | Behavior |
|---------|----------|
| EXPERIENCE section | Select "Client" role |
| LEGACY section | Select "Pro" role |

**Navigation:** → `/signup` with role as extra parameter

### 3.4 Sign Up Flow

**Fields:** Role (pre-filled), Full Name, Email, Phone, Age, Address, Password  
**Validation:**
- Name: required
- Email: valid format, required
- Password: minimum 6 characters

**Auth method:** `supabase.auth.signUp(email, password)` + profile insert  
**Navigation:** → `/complete-profile`

### 3.5 Login Flow

**Elements:**
1. Role toggle (Client / Pro)
2. Email field
3. Password field
4. "Forgot Password?" link
5. "Sign In" button
6. Google Sign-In button
7. Apple Sign-In button (placeholder)
8. "Don't have an account? Sign Up" link

**Auth methods:**
- Email/Password: `supabase.auth.signInWithPassword()`
- Google OAuth: `supabase.auth.signInWithOAuth(OAuthProvider.google)`

**Navigation after login:**
- role = 'client' → `/client/feed`
- role = 'pro' → `/pro/dashboard`
- no profile → `/complete-profile`

### 3.6 Complete Profile

**Fields:** Avatar (image picker), Display Name, Bio  
**Navigation:** 
- Client → `/client/interests`
- Pro → `/pro/business-details`

### 3.7 Client Onboarding Continuation

| Step | Screen | Elements |
|------|--------|----------|
| 1 | ClientInterestCategoriesScreen | 2×4 grid of categories, progress bar, min 1 selection |
| 2 | ClientInterestGoalsScreen | 4 goal options, single selection |
| 3 | PermissionLocationScreen | "Allow Location" button, "Not Now" link |

**Categories:** Hair & Beauty, Wellness, Photography, Fitness, Tattoo, Makeup, Nails, Fashion  
**Goals:** Discover new pros, Book appointments, Attend events, Compare prices  
**Final navigation:** → `/client/feed`

### 3.8 Pro Onboarding Continuation

| Step | Screen | Elements |
|------|--------|----------|
| 1 | ProBusinessDetailsScreen | Business name, category dropdown, city, bio |
| 2 | ProVerificationScreen | Phone number, upload ID document |
| 3 | StripeConnectScreen | "Connect Stripe" button, trust badges |

**Service categories:** Coiffure, Barbier, Esthétique, Massage, Fitness, Photo, Tattoo, Maquillage, Ongles, Mode  
**Final navigation:** → `/pro/dashboard`

---

## 4. Navigation Structure

### 4.1 Client Shell (BottomNavigationBar — 4 tabs)

| Tab | Icon | Label | Route | Screen |
|-----|------|-------|-------|--------|
| 0 | home | Feed | `/client/feed` | FeedScreen |
| 1 | search | Discover | `/client/discover` | DiscoverScreen |
| 2 | calendar_today | My Bookings | `/client/bookings` | MyBookingsScreen |
| 3 | person | Profile | `/client/profile` | ClientProfileScreen |

### 4.2 Pro Shell (BottomNavigationBar — 5 tabs)

| Tab | Icon | Label | Route | Screen |
|-----|------|-------|-------|--------|
| 0 | home | Feed | `/pro/feed` | FeedScreen |
| 1 | search | Discover | `/pro/discover` | DiscoverScreen |
| 2 | videocam | Camera | `/pro/camera` | UploadVideoScreen |
| 3 | calendar_today | Bookings | `/pro/bookings` | MyBookingsScreen |
| 4 | dashboard | Dashboard | `/pro/dashboard` | ProDashboardScreen |

### 4.3 Shared Routes (Accessible from both roles)

| Route | Screen | Parameters |
|-------|--------|------------|
| `/settings` | SettingsScreen | — |
| `/delete-account` | DeleteAccountScreen | — |
| `/my-videos` | MyVideosScreen | — |
| `/upload-video` | UploadVideoScreen | — |
| `/chat/:conversationId` | ChatScreen | conversationId (path) |
| `/notifications` | NotificationHistoryScreen | — |
| `/notification-settings` | NotificationSettingsScreen | — |
| `/edit-profile` | EditProfileScreen | — |
| `/pro/:proId` | ProProfileScreen | proId (path) |
| `/event/:eventId` | EventDetailScreen | eventId (path) |
| `/create-event` | CreateEventScreen | — |
| `/ticket-detail` | TicketDetailScreen | TicketModel (extra) |
| `/scanner/:eventId` | ScannerScreen | eventId (path) |
| `/waitlist` | WaitlistScreen | ticketTypeId, eventTitle (extra) |
| `/booking/:bookingId` | PlaceholderScreen | bookingId (path) |
| `/cancel-booking/:bookingId` | BookingCancellationScreen | bookingId (path) |
| `/pro-subscription` | ProSubscriptionScreen | — |
| `/subscription-checkout` | StripeCheckoutWebview | url (extra) |
| `/review` | ReviewScreen | bookingId, proId, serviceName (extra) |
| `/favorites` | FavoritesScreen | — |
| `/promo-codes` | CreatePromoCodeScreen | — |
| `/referral` | ReferralScreen | — |
| `/blocked-users` | BlockedUsersScreen | — |
| `/pro-insights` | ProInsightsScreen | — |

---

## 5. Screen-by-Screen Specifications

### 5.1 FeedScreen

**Purpose:** TikTok-style vertical video feed displaying approved pro videos  
**Provider:** `feedProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Layout | Fullscreen vertical PageView |
| Video player | better_player_plus, auto-play, loop |
| Gradient overlay | Bottom LinearGradient transparent → black (40% opacity) |
| Pro info | Avatar + name + business name (bottom-left) |
| Like button | Heart icon with count, AnimatedScale 1.0→1.3→1.0 (300ms), HapticFeedback.lightImpact |
| Comment button | Opens CommentsSheet (bottom sheet) |
| Share button | share_plus |
| Book button | Opens BookingBottomSheet |

**Constraints:**
- Only videos with `status = 'approved'` appear in feed
- Infinite scroll with pagination
- Pull-to-refresh

### 5.2 DiscoverScreen

**Purpose:** Search and filter professionals  
**Provider:** `discoverProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Search bar | Text input at top, real-time filtering |
| Category chips | Horizontal scroll: All, Coiffure, Beauté, Fitness, Photo, Tattoo, Maquillage, Ongles |
| Filter bottom sheet | Distance, Rating, Price range, Availability |
| Results grid | 2-column grid of pro cards |
| Pro card | Cover image, avatar, name, category, rating, city |

**Interactions:** Tap on pro card → `/pro/:proId`

### 5.3 MyBookingsScreen

**Purpose:** View client's bookings  
**Provider:** `clientBookingsProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Tabs | "Upcoming" / "Past" / "Cancelled" |
| Booking card | Service name, pro name, date/time, status badge, amount |
| Cancel button | On upcoming bookings → `/cancel-booking/:bookingId` |

**Booking statuses:** `pending_payment`, `confirmed`, `completed`, `cancelled`, `refunded`

### 5.4 ClientProfileScreen

**Purpose:** Client's own profile  
**Provider:** `clientProfileProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Header | Cover image + avatar + full name + @username + city |
| Edit button | → `/edit-profile` |
| Settings icon | → `/settings` |
| Tab 1: Favorites | List of favorited pros and events |
| Tab 2: Booking History | Past completed bookings |
| Tab 3: My Tickets | Purchased event tickets |

### 5.5 ProProfileScreen

**Purpose:** View a professional's public profile  
**Provider:** `proProfileProvider(proId)` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Header | Cover + avatar + name + "TOP PRO" badge (if is_top_pro) |
| Rating | Stars + average_rating + review_count |
| Social badges | Instagram/TikTok/YouTube with handle + followers |
| Bio | Description text |
| Action buttons | "Book Appointment" → BookingBottomSheet, "Buy Event Ticket" |
| Menu | Report (opens ReportSheet), Block |

### 5.6 ProDashboardScreen

**Purpose:** Pro's main dashboard with stats  
**Provider:** `proDashboardProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Stats grid | Total bookings, Revenue, Average rating, Pending bookings |
| Upcoming list | Next appointments with client info, date, service |
| Pull-to-refresh | RefreshIndicator |

### 5.7 UploadVideoScreen

**Purpose:** Pro uploads a service video  
**Provider:** `uploadVideoProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Video picker | image_picker, from gallery |
| Title field | 5–80 characters, required |
| Category dropdown | Required, from _allowedCategories list |
| Description field | Min 20 characters, required |
| Hashtags field | Optional comma-separated tags |
| Publish button | Disabled until form valid |

**Allowed categories:** coiffure, beaute, fitness, photo, tattoo, maquillage, ongles, mode, massage, barbier  
**Upload flow:** Pick video → compress (video_compress) → get TUS URL (Edge Function) → upload to Cloudflare Stream → insert DB record  
**Post-upload status:** `pending_review` (goes through `moderate-video` Edge Function)  
**Exception:** TOP PRO videos are auto-approved

### 5.8 MyVideosScreen

**Purpose:** Pro sees their uploaded videos  
**Provider:** `myVideosProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Video list | ListView with thumbnail, title, status badge, views/likes/comments |
| Status badges | pending_review (yellow), approved (green), rejected (red), flagged (orange) |
| Delete action | Swipe-to-delete or delete icon |

### 5.9 EventDetailScreen

**Purpose:** View event details and buy tickets  
**Provider:** `eventDetailProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Header | SliverAppBar with cover image |
| Info | Title, date/time, location/address, description |
| Pro section | Pro avatar + name (tappable → ProProfileScreen) |
| Ticket types | List of available ticket types with name + price + remaining |
| Buy button | Opens BuyTicketSheet bottom sheet |

### 5.10 CreateEventScreen

**Purpose:** Pro creates a new event  
**Provider:** `_createProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Cover picker | Image from gallery |
| Title field | Required |
| Description field | Optional |
| Date picker | Required, future date |
| Location field | Required |
| Ticket types | Dynamic list: name + price + quantity per type |
| Publish button | Submits event |

### 5.11 TicketDetailScreen

**Purpose:** Display a purchased ticket with QR code  
**Provider:** None (stateless, receives TicketModel as extra)

| Element | Spec |
|---------|------|
| QR code | Generated via qr_flutter from `qr_hash` |
| Event info | Title, date, location |
| Ticket info | Type name, purchase date, status |
| Actions | Share (share_plus), Add to calendar (add_2_calendar) |

### 5.12 ScannerScreen

**Purpose:** Pro scans QR tickets at event entry  
**Provider:** `_scannerProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Camera | MobileScanner widget |
| Overlay | Scan result: valid (green) / invalid (red) / already scanned (orange) |
| Haptic | HapticFeedback.heavy on scan result |

**Validation:** QR hash sent to `validate-qr-ticket` Edge Function

### 5.13 BookingBottomSheet

**Purpose:** Multi-step booking flow  
**Provider:** `BookingFlowNotifier` (AsyncNotifier)

| Step | Content |
|------|---------|
| 1 — Service | Select from pro's services list (name, duration, price) |
| 2 — Date | Calendar date picker |
| 3 — Time slot | Available time slots for selected date |
| 4 — Promo code | Optional promo code input + apply |
| 5 — Summary | Service, date, time, price breakdown (deposit amount, commission) |
| 6 — Payment | Stripe payment via flutter_stripe |

**After payment:** Creates booking via `create-booking-atomic` Edge Function

### 5.14 BookingCancellationScreen

**Purpose:** Cancel an upcoming booking  
**Provider:** `clientBookingsProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Policy display | Cancellation policy text |
| Confirm button | Calls `cancel-booking` Edge Function |

**Refund rules:**
- < 48h before appointment: pro keeps deposit
- > 48h before appointment: full refund via Stripe

### 5.15 ChatScreen

**Purpose:** Real-time messaging between client and pro  
**Provider:** `chatProvider(conversationId)` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Messages | ListView of message bubbles (text + optional image) |
| Input | Text field + image picker button + send button |
| Real-time | Supabase Realtime subscription |

### 5.16 FavoritesScreen

**Purpose:** View favorited pros and events  
**Provider:** `favoritesListProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Tabs | "Pros" / "Events" |
| Pro list | Avatar, name, category, rating |
| Event list | Cover, title, date, location |

**Interactions:** Tap → `/pro/:proId` or `/event/:eventId`

### 5.17 NotificationHistoryScreen

**Purpose:** Notification inbox  
**Provider:** `notificationListProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| List | ListView of notifications with icon, title, body, timestamp |
| Swipe-to-delete | Dismissible |
| Mark as read | Tap on notification |
| Deep links | Tap navigates to `/booking/:id`, `/chat/:id`, or `/event/:id` |

### 5.18 NotificationSettingsScreen

**Purpose:** Toggle notification preferences  
**Provider:** `notifPrefsProvider` (AsyncNotifier)

| Toggle | Default |
|--------|---------|
| Booking reminders | ON |
| Booking updates | ON |
| Messages | ON |
| Review requests | ON |
| Waitlist | ON |
| Marketing | ON |

### 5.19 SettingsScreen

**Purpose:** App settings hub  
**Provider:** `analyticsConsentProvider` (AsyncNotifier)

| Section | Items |
|---------|-------|
| Account | Edit Profile, Notification Settings, Favorites |
| Security | Blocked Users |
| Promo | Promo Codes (pro), Referral |
| Social | Pro Insights (pro) |
| Support | Help Center, Contact |
| Legal | Privacy Policy, Terms, GDPR toggle |
| Danger | Log Out, Delete Account |

**Log Out:** Calls `supabase.auth.signOut()` → navigates to `/login`

### 5.20 DeleteAccountScreen

**Purpose:** Permanently delete account  
**Provider:** `_deleteProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Warning text | Explanation of consequences |
| Confirmation checkbox | Must be checked to enable delete button |
| Delete button | Calls auth repo delete → navigates to `/login` |

### 5.21 EditProfileScreen

**Purpose:** Edit user profile fields  
**Provider:** `editProfileProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Display name | Text field |
| Username | Text field |
| City | Text field |
| Bio | Multiline text field |
| Social links | Instagram, TikTok, YouTube handles (pro only) |

### 5.22 ReviewScreen

**Purpose:** Leave a review after a completed booking  
**Provider:** `_reviewProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Star rating | 5 stars, tap to rate (1–5) |
| Comment | Multiline text field |
| Submit button | Creates review record |

**Parameters received:** bookingId, proId, serviceName (via GoRouter extra)

### 5.23 ProSubscriptionScreen

**Purpose:** Subscribe to Pro Premium  
**Provider:** `_subProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
*Screen removed — no premium subscription tier.*

### 5.24 ProInsightsScreen

**Purpose:** Pro analytics and performance metrics  
**Provider:** `proInsightsProvider` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Period chips | 7 days / 30 days / 90 days |
| Revenue chart | fl_chart line graph |
| Metrics | Total revenue, bookings count, average rating, video views |

### 5.25 ReferralScreen

**Purpose:** Referral program  
**Provider:** `_referralProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Referral code | Displayed prominently |
| Copy button | Copies to clipboard |
| Share button | share_plus |
| Stats | Number of referrals, rewards earned |

### 5.26 CreatePromoCodeScreen

**Purpose:** Pro creates and manages promo codes  
**Provider:** `_promoListProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Form | Code, discount (1–100%), max uses, expiry date |
| Active codes list | Code, discount, usage stats, toggle active/inactive |

### 5.27 BlockedUsersScreen

**Purpose:** Manage blocked users  
**Provider:** `_blockedProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| List | Blocked user avatar + name |
| Unblock button | Per-user unblock action |

### 5.28 WaitlistScreen

**Purpose:** Join waitlist for sold-out ticket type  
**Provider:** `_waitlistProvider` (local AsyncNotifier)

| Element | Spec |
|---------|------|
| Info | Event title + ticket type |
| Join button | Adds user to waitlist with position |

### 5.29 ReportSheet (Bottom Sheet)

**Purpose:** Report a user or content  
**Provider:** `reportNotifier` (AsyncNotifier)

| Element | Spec |
|---------|------|
| Reasons | Inappropriate content, Spam, Harassment, Fraud, Other |
| Submit button | Creates report record |

---

## 6. Shared Widgets

| Widget | File | Spec |
|--------|------|------|
| **SpotbookButton** | `spotbook_button.dart` | Variants: primary (white bg/black text), secondary (#1A1A1A bg/white text), outlined. ScaleTransition 95% on tap (100ms). HapticFeedback.mediumImpact on primary. BorderRadius 12. Min height 48px. |
| **SpotbookCard** | `spotbook_card.dart` | Surface background, padding 16, borderRadius 16, subtle shadow, optional onTap |
| **EmptyState** | `empty_state.dart` | Icon + title + subtitle, centered, used when lists are empty |
| **ShimmerList** | `shimmer_list.dart` | Shimmer loading placeholder, used instead of CircularProgressIndicator |
| **SocialBadge** | `social_badge.dart` | Platform icon (Instagram/TikTok/YouTube) + handle + follower count |
| **OfflineBanner** | `offline_banner.dart` | "No connection" banner via connectivity_plus, shown at top when offline |
| **ConsentBanner** | `consent_banner.dart` | GDPR cookie consent: Accept / Refuse buttons, controls PostHog analytics |
| **PlaceholderScreen** | `placeholder_screen.dart` | Temporary screen with centered title text |
| **FavoriteHeartButton** | `favorite_heart_button.dart` | Animated heart toggle, HapticFeedback.lightImpact |
| **LikeAnimation** | `like_animation.dart` | Double-tap like animation on videos |

---

## 7. Data Models

### 7.1 VideoModel
```
id: String
proId: String
cloudflareId: String?
streamUrl: String?
thumbnailUrl: String?
title: String
hashtags: List<String>
category: String
status: String (pending_review | approved | rejected | flagged)
likesCount: int
commentsCount: int
viewsCount: int
createdAt: DateTime
```

### 7.2 BookingModel
```
id: String
clientId: String
proId: String
serviceId: String
timeSlotId: String
status: String (pending_payment | confirmed | completed | cancelled | refunded)
depositAmount: double
totalAmount: double
currency: String (default: CAD)
stripePaymentIntentId: String?
promoCodeId: String?
bookingCode: String
createdAt: DateTime
```

### 7.3 ServiceModel
```
id: String
proId: String
name: String
description: String?
durationMinutes: int
price: double
isActive: bool
```

### 7.4 TimeSlotModel
```
id: String
proId: String
date: DateTime
startTime: String
endTime: String
isAvailable: bool
```

### 7.5 EventModel
```
id: String
proId: String
title: String
description: String?
coverUrl: String?
eventDate: DateTime
location: String
address: String?
isActive: bool
createdAt: DateTime
```

### 7.6 TicketTypeModel
```
id: String
eventId: String
name: String
price: double
quantity: int
soldCount: int
```

### 7.7 TicketModel
```
id: String
eventId: String
ticketTypeId: String
userId: String
stripePaymentIntentId: String?
qrHash: String?
status: String (valid | used | cancelled)
scannedAt: DateTime?
purchasedAt: DateTime
```

### 7.8 ClientProfile
```
id: String
email: String?
fullName: String?
username: String?
avatarUrl: String?
coverUrl: String?
bio: String?
city: String?
country: String?
```

### 7.9 ProProfile
```
id: String
fullName: String?
username: String?
avatarUrl: String?
coverUrl: String?
businessName: String?
category: String?
description: String?
averageRating: double
reviewCount: int
isTopPro: bool
socialConnections: List<SocialConnection>
```

### 7.10 ConversationModel / MessageModel
```
ConversationModel:
  id: String
  bookingId: String
  clientId: String
  proId: String
  createdAt: DateTime

MessageModel:
  id: String
  conversationId: String
  senderId: String
  content: String?
  imageUrl: String?
  readAt: DateTime?
  createdAt: DateTime
```

### 7.11 NotificationModel
```
id: String
userId: String
type: String
title: String
body: String
resourceId: String?
isRead: bool
createdAt: DateTime
```

### 7.12 ReviewModel
```
id: String
bookingId: String
clientId: String
proId: String
rating: int (1–5)
comment: String?
createdAt: DateTime
```

### 7.13 PromoCodeDetail
```
id: String
proId: String
code: String
discountType: String
discountValue: double
maxUses: int
usesCount: int
expiresAt: DateTime?
isActive: bool
```

### 7.14 FavoriteModel
```
userId: String
targetId: String
targetType: String (pro | event)
```

---

## 8. Business Rules & Validation

### 8.1 Video Rules
- Only Pros can upload videos
- Max duration: 60 seconds
- Required fields: title (5–80 chars), category (from allowed list), description (min 20 chars)
- All videos go through `moderate-video` before becoming visible
- Status flow: `pending_review` → `approved` | `rejected` | `flagged`
- Feed only shows videos with `status = 'approved'`
- TOP PRO: videos are auto-approved immediately
- A video flagged 3 times is automatically hidden

### 8.2 Booking Rules
- Deposit is required at booking time via Stripe
- Commission: 18% on all bookings (same rate for all Pros)
- Client service fee: $2.50 per booking
- Cancellation > 48h before: full refund
- Cancellation < 48h before: pro keeps the deposit
- If refund occurs after payout: Transfer Reversal is required
- All Stripe amounts are in cents (×100)
- Each PaymentIntent must have an idempotency_key

### 8.3 Event & Ticket Rules
- Commission on ticket sales: 12%
- QR hash is generated server-side only (never in Flutter)
- QR validation goes through `validate-qr-ticket` Edge Function
- Ticket statuses: `valid` → `used` (after scan) or `cancelled`
- Sold-out tickets offer a waitlist

### 8.4 Payment Rules
- Payment provider: Stripe for ALL users, no exceptions
- No PawaPay, Mobile Money, Orange Money, Wave, MTN MoMo
- No Stripe secret keys (`sk_xxx`) in Flutter — Edge Functions only
- All monetary amounts in Stripe are in cents

### 8.5 TOP PRO Criteria
- Average rating >= 4.8
- Review count >= 10
- Calculated automatically via database trigger

### 8.6 Form Validations Summary

| Screen | Field | Rule |
|--------|-------|------|
| SignUpScreen | Name | Required |
| SignUpScreen | Email | Valid email format |
| SignUpScreen | Password | Min 6 characters |
| UploadVideoScreen | Title | 5–80 characters |
| UploadVideoScreen | Category | Required, from predefined list |
| UploadVideoScreen | Description | Min 20 characters |
| UploadVideoScreen | Video | Required, max 60s |
| CreateEventScreen | Title | Required |
| CreateEventScreen | Location | Required |
| CreatePromoCodeScreen | Code | Non-empty |
| CreatePromoCodeScreen | Discount | 1–100% |
| ProBusinessDetailsScreen | Business name | Required |
| ProBusinessDetailsScreen | Category | Required |
| ReviewScreen | Rating | 1–5 stars |

---

## 9. Design System

### 9.1 Colors (AppColors)

| Token | Hex | Usage |
|-------|-----|-------|
| `fond` | `#000000` | Scaffold background |
| `surface` | `#111111` | Cards, sheets, dialogs |
| `surfaceAlt` | `#1A1A1A` | Secondary buttons, inputs |
| `surfaceAuth` | `#1A1A2E` | Auth screens background |
| `border` | `#2A2A2A` | Dividers, outlines |
| `blanc` | `#FFFFFF` | Primary text, primary buttons |
| `gris` | `#888888` | Secondary text |
| `grisClair` | `#CCCCCC` | Hints, placeholders |
| `success` | `#00C851` | Success states |
| `error` | `#FF4444` | Error states, rejected |
| `warning` | `#FFBB33` | Warning states, pending |

**Rule:** No hex colors in widget code — use `AppColors.xxx` exclusively.  
**Rule:** No decorative colors (purple, cyan, orange) — strict black & white.

### 9.2 Typography

- Font: SF Pro (iOS) / Roboto (Android) — system default
- Headlines: Bold, letterSpacing 0.5
- Body: Regular, lineHeight ≥ 1.5
- Labels: Medium, UPPERCASE for categories
- Minimum font size: 12sp

### 9.3 Spacing & Layout

- Horizontal padding: 20px minimum on all screens
- Section spacing: 24px minimum
- Card border radius: 16px
- Button border radius: 12px
- Shadow: `0px 2px 8px rgba(0,0,0,0.3)`
- Touch targets: 48px minimum

### 9.4 Required Animations

| Element | Animation |
|---------|-----------|
| Page transitions | FadeTransition, 200ms |
| Button press | ScaleTransition 95%, 100ms |
| List items | Staggered reveal, 50ms between items |
| Like/Favorite | AnimatedScale 1.0→1.3→1.0, 300ms |
| Loading | ShimmerEffect (never bare CircularProgressIndicator) |
| Pull to refresh | White RefreshIndicator |

### 9.5 Required Haptics

| Action | Haptic |
|--------|--------|
| Like, Favorite, Follow | HapticFeedback.lightImpact() |
| Primary buttons | HapticFeedback.mediumImpact() |
| QR scan valid/invalid | HapticFeedback.heavy() |
| Slot/category selection | HapticFeedback.selectionClick() |

### 9.6 Image Loading

All images use `CachedNetworkImage` with:
- Placeholder: ShimmerPlaceholder
- Error widget: Container(color: surface, child: Icon(white))
- Fit: BoxFit.cover

---

## 10. Error States & Edge Cases

### 10.1 Network Errors
- OfflineBanner shown when connectivity lost (connectivity_plus)
- All async operations show shimmer during loading
- Failed operations show SnackBar (surface background, white text, radius 12, 2s duration)

### 10.2 Empty States
- EmptyState widget with icon + title + subtitle for:
  - No bookings
  - No videos
  - No notifications
  - No favorites
  - No search results
  - No messages

### 10.3 Authentication Edge Cases
- Session expired → redirect to `/onboarding`
- No role set → redirect to `/onboarding`
- Deep link without auth → no global guard (known limitation)

### 10.4 Payment Edge Cases
- Payment failure → show error SnackBar, keep booking in `pending_payment`
- Double payment → idempotency_key prevents duplicate charges
- Refund after payout → Transfer Reversal via Edge Function

### 10.5 Video Edge Cases
- Video too long (>60s) → validation error before upload
- Upload interrupted → video stays in `pending_review`
- Moderation rejection → video status set to `rejected`, not shown in feed
- 3 flags → video automatically hidden

---

## 11. Dependencies

### 11.1 Production Dependencies

| Category | Package | Version |
|----------|---------|---------|
| Backend | supabase_flutter | ^2.5.0 |
| Backend | firebase_core | ^4.5.0 |
| Backend | firebase_messaging | ^16.1.2 |
| State | flutter_riverpod | ^3.3.1 |
| State | riverpod_annotation | ^4.0.2 |
| Navigation | go_router | ^17.1.0 |
| Auth | google_sign_in | ^7.2.0 |
| Payments | flutter_stripe | ^12.4.0 |
| Video | better_player_plus | ^1.1.5 |
| Video | video_compress | ^3.1.2 |
| Media | image_picker | ^1.1.2 |
| QR | qr_flutter | ^4.1.0 |
| QR | mobile_scanner | ^7.2.0 |
| UI | cached_network_image | ^3.3.1 |
| UI | shimmer | ^3.0.0 |
| UI | lottie | ^3.1.0 |
| Charts | fl_chart | ^1.2.0 |
| Sharing | share_plus | ^12.0.1 |
| Calendar | add_2_calendar | ^3.0.1 |
| Storage | hive_flutter | ^1.1.0 |
| Storage | flutter_secure_storage | ^10.0.0 |
| Network | connectivity_plus | ^7.0.0 |
| Location | geolocator | ^14.0.2 |
| Biometric | local_auth | ^3.0.1 |
| Deep links | app_links | ^6.1.1 |
| i18n | intl | ^0.20.2 |
| Analytics | posthog_flutter | ^5.20.0 |
| Monitoring | sentry_flutter | ^9.15.0 |

### 11.2 Dev Dependencies

| Package | Version |
|---------|---------|
| flutter_test | SDK |
| build_runner | ^2.4.9 |
| riverpod_generator | ^4.0.3 |
| flutter_lints | ^6.0.0 |
| flutter_launcher_icons | ^0.14.4 |
| flutter_native_splash | ^2.4.0 |

---

## 12. Database Schema (26 tables)

| # | Table | Key Fields | RLS |
|---|-------|------------|-----|
| 1 | `users` | id, email, full_name, username, avatar_url, cover_url, bio, role (client\|pro), city, country, currency, payment_provider, fcm_token, is_verified, deleted_at | Yes |
| 2 | `profiles_pro` | id (FK users), business_name, category, description, stripe_account_id, stripe_onboarded, commission_rate (0.12), average_rating, review_count, is_top_pro, kyc_status | Yes |
| 3 | `social_connections` | id, pro_id, platform (instagram\|tiktok\|youtube), handle, followers_count, access_token, refresh_token | Yes |
| 4 | `services` | id, pro_id, name, description, duration_minutes, price, is_active | Yes |
| 5 | `availability_rules` | id, pro_id, day_of_week (0–6), start_time, end_time, slot_duration_minutes | Yes |
| 6 | `time_slots` | id, pro_id, date, start_time, end_time, is_available, locked_by | Yes |
| 7 | `bookings` | id, client_id, pro_id, service_id, time_slot_id, status, deposit_amount, total_amount, currency, stripe_payment_intent_id, transfer_id, refund_amount, refund_status, promo_code_id, booking_code | Yes |
| 8 | `videos` | id, pro_id, cloudflare_id, stream_url, thumbnail_url, title, hashtags[], category, status, likes_count, comments_count, views_count | Yes |
| 9 | `video_likes` | user_id, video_id (composite PK) | Yes |
| 10 | `video_comments` | id, video_id, user_id, content | Yes |
| 11 | `events` | id, pro_id, title, description, cover_url, event_date, location, address, is_active | Yes |
| 12 | `ticket_types` | id, event_id, name, price, quantity, sold_count | Yes |
| 13 | `tickets` | id, event_id, ticket_type_id, user_id, stripe_payment_intent_id, qr_hash, status (valid\|used\|cancelled), scanned_at | Yes |
| 14 | `waitlist` | id, ticket_type_id, user_id, position, notified_at, expires_at | Yes |
| 15 | `conversations` | id, booking_id (unique), client_id, pro_id | Yes |
| 16 | `messages` | id, conversation_id, sender_id, content, image_url, read_at, typing_at | Yes |
| 17 | `notifications` | id, user_id, type, title, body, resource_id, is_read | Yes |
| 18 | `notification_preferences` | user_id (PK), bookings, messages, reminders, promotions (all bool) | Yes |
| 19 | `favorites` | user_id, target_id, target_type (pro\|event) (composite PK) | Yes |
| 20 | `follows` | follower_id, following_id (composite PK) | Yes |
| 21 | `blocks` | blocker_id, blocked_id (composite PK) | Yes |
| 22 | `reviews` | id, booking_id (unique), client_id, pro_id, rating (1–5), comment | Yes |
| 23 | `promo_codes` | id, pro_id, code (unique), discount_type, discount_value, max_uses, uses_count, expires_at, is_active | Yes |
| 24 | `app_config` | key (PK), value, description | Yes |
| 25 | `referrals` | id, referrer_id, referred_id, referral_code, reward_given | Yes |
| 26 | `reports` | id, reporter_id, target_id, target_type, reason | Yes |

**Trigger:** `update_top_pro` — after INSERT/UPDATE on reviews, recalculates `average_rating`, `review_count`, and `is_top_pro` (>=4.8 avg AND >=10 reviews).

---

## 13. Edge Functions (Backend)

| Function | Purpose | Auth Required |
|----------|---------|---------------|
| `create-booking-atomic` | Atomic booking creation + Stripe PaymentIntent | Yes |
| `cancel-booking` | Cancel booking + Stripe refund | Yes |
| `generate-slots` | Cron: generate time slots for pros | Service role |
| `stripe-create-intent` | Create PaymentIntent for booking deposit | Yes |
| `stripe-create-ticket-intent` | Create PaymentIntent for ticket purchase | Yes |
| `stripe-webhook-handler` | Handle Stripe webhooks (payment, transfer) | Stripe signature |
| `create-pro-subscription` | Create Pro Premium subscription | Yes |
| `process-payout` | Pay pro via Stripe Connect transfer | Yes |
| `generate-cloudflare-upload-url` | Get TUS upload URL for Cloudflare Stream | Yes |
| `moderate-video` | AI moderation of uploaded videos | Yes |
| `validate-qr-ticket` | Validate QR code at event entry | Yes |
| `sign-qr-ticket` | HMAC sign QR hash | Yes |
| `send-push-notification` | Send FCM push notification | Service role |
| `schedule-reminders` | Cron: send J-1 booking reminders | Service role |
| `trigger-review-request` | Cron: request review after booking | Service role |
| `sync-social-stats` | Sync social platform follower counts | Service role |
| `link-instagram` | Instagram OAuth connection | Yes |
| `link-tiktok` | TikTok OAuth connection | Yes |
| `link-youtube` | YouTube OAuth connection | Yes |
| `rate-limiter` | Rate limiting (login, OTP, payment) | Yes |

---

## 14. Test Checklist

### 14.1 Authentication Tests

- [ ] Splash screen redirects correctly based on session state
- [ ] Onboarding shows 3 slides with correct content
- [ ] Skip button navigates to login
- [ ] Get Started navigates to account type selection
- [ ] Account type selection shows Client and Pro options
- [ ] Sign up validates all required fields
- [ ] Sign up with invalid email shows error
- [ ] Sign up with short password (<6 chars) shows error
- [ ] Login with valid credentials navigates to correct feed
- [ ] Login with invalid credentials shows error
- [ ] Google OAuth triggers Supabase OAuth flow
- [ ] Complete profile allows avatar upload
- [ ] Client onboarding: categories require min 1 selection
- [ ] Client onboarding: goals allow single selection
- [ ] Client onboarding: location permission handles allow/deny
- [ ] Pro onboarding: business details validates required fields
- [ ] Pro onboarding: verification handles document upload
- [ ] Logout clears session and navigates to login
- [ ] Delete account requires checkbox confirmation

### 14.2 Navigation Tests

- [ ] Client shell shows 4 tabs (Feed, Discover, Bookings, Profile)
- [ ] Pro shell shows 5 tabs (Feed, Discover, Camera, Bookings, Dashboard)
- [ ] Tab switching preserves state
- [ ] Back navigation works correctly from all screens
- [ ] Deep links navigate to correct screens
- [ ] GoRouter extra parameters pass correctly (TicketModel, bookingId, etc.)

### 14.3 Feed Tests

- [ ] Feed loads approved videos only
- [ ] Vertical swipe navigates between videos
- [ ] Like button toggles with animation
- [ ] Like triggers HapticFeedback.lightImpact
- [ ] Comment button opens bottom sheet
- [ ] Share button triggers share_plus
- [ ] Video auto-plays when visible
- [ ] Video pauses when swiped away
- [ ] Pull-to-refresh reloads feed
- [ ] Empty state shown when no videos

### 14.4 Discover Tests

- [ ] Search bar filters professionals in real-time
- [ ] Category chips filter results
- [ ] Filter sheet opens with distance/rating/price/availability
- [ ] Pro cards show correct info (name, category, rating, city)
- [ ] Tap on pro card navigates to ProProfileScreen
- [ ] Empty state shown when no results

### 14.5 Booking Tests

- [ ] Booking bottom sheet shows all 6 steps
- [ ] Service selection shows pro's active services
- [ ] Date picker shows available dates
- [ ] Time slot selection shows available slots
- [ ] Promo code application updates price
- [ ] Summary shows correct breakdown (service, date, time, deposit)
- [ ] Payment triggers Stripe flow
- [ ] MyBookings tabs show correct bookings per status
- [ ] Cancellation screen shows policy
- [ ] Cancellation button calls Edge Function

### 14.6 Event & Ticket Tests

- [ ] Event detail shows cover, date, location, description
- [ ] Ticket types show name, price, remaining
- [ ] Buy ticket sheet processes Stripe payment
- [ ] Ticket detail shows QR code
- [ ] Ticket share and calendar add work
- [ ] Scanner camera activates
- [ ] Scanner validates QR via Edge Function
- [ ] Valid scan shows green overlay with HapticFeedback.heavy
- [ ] Invalid scan shows red overlay with HapticFeedback.heavy
- [ ] Waitlist join works for sold-out tickets

### 14.7 Profile Tests

- [ ] Client profile shows cover, avatar, name, username, city
- [ ] Client profile tabs (Favorites, History, Tickets) load correctly
- [ ] Pro profile shows rating, social badges, bio
- [ ] Pro profile "TOP PRO" badge shows when is_top_pro = true
- [ ] Book Appointment button opens booking sheet
- [ ] Report and Block menu items work
- [ ] Edit profile saves changes
- [ ] Social links display correctly for pro

### 14.8 Video Upload Tests (Pro only)

- [ ] Video picker opens gallery
- [ ] Video > 60s shows validation error
- [ ] Title validation: 5–80 characters
- [ ] Description validation: min 20 characters
- [ ] Category dropdown shows allowed categories
- [ ] Publish button disabled until form valid
- [ ] Upload progress shown
- [ ] Video appears in MyVideosScreen with pending_review status

### 14.9 Chat Tests

- [ ] Messages load correctly
- [ ] Real-time messages appear without refresh
- [ ] Text input and send button work
- [ ] Image picker and send work
- [ ] Message bubbles distinguish sender/receiver

### 14.10 Settings & Notifications Tests

- [ ] All settings sections render correctly
- [ ] Notification toggles save preferences
- [ ] Notification list loads with correct content
- [ ] Swipe-to-delete works on notifications
- [ ] GDPR toggle controls analytics consent
- [ ] Blocked users list shows and allows unblock

### 14.11 UI/UX Tests

- [ ] All screens use AppColors (no hardcoded hex)
- [ ] ShimmerList shown during loading (no bare CircularProgressIndicator)
- [ ] CachedNetworkImage used for all network images
- [ ] Touch targets minimum 48px
- [ ] Text never below 12sp
- [ ] SnackBars have surface background, white text, radius 12
- [ ] AlertDialogs have surface background, radius 20
- [ ] Buttons have correct ScaleTransition on tap
- [ ] Page transitions use FadeTransition 200ms

### 14.12 Error Handling Tests

- [ ] Network loss shows OfflineBanner
- [ ] API errors show SnackBar with message
- [ ] Empty lists show EmptyState widget
- [ ] Form validation errors display inline
- [ ] Payment failure shows appropriate error

---

*This document should be updated as new features are added or existing ones are modified.*
