# Premium UI/UX & Offline Resilience for Kurichiyar Matrimony

Elevate the app's professional feel with smooth animations and ensure it remains functional under poor network conditions through robust offline caching.

## User Review Required

- **Offline Indicator**: Proposed a subtle snackbar or a small "Offline" banner in the AppBar. Does the user have a preference for its visibility?
- **Sync Strategy**: Background sync currently clears the queue on restoration. Should we add a retry mechanism for failed sync items?

## Proposed Changes

### Core UI & Animation

#### [NEW] [premium_ui_utils.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/core/utils/premium_ui_utils.dart)
- `ShimmerPlaceholder`: Reusable skeleton loader using `flutter_animate`.
- `AnimatedTabBody`: A wrapper for smooth tab transitions using `AnimatedSwitcher`.

#### [dashboard_shell.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/features/dashboard/dashboard_shell.dart)
- Integrate `AnimatedTabBody` for smooth tab switches.
- Add `Connectivity` listener to show a "You are offline" message when needed.

#### [home_tab.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/features/dashboard/home_tab.dart)
- **Clean Profile Cards**: Simplified UI showing Image, Name, Age, Tharavad, and Profession.
- **Micro-animations**: Fade-in entrance for profile cards.
- **Shimmer Loading**: Replace spinner with skeleton loaders during data fetch.

#### [NEW] [profile_detail_view.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/features/dashboard/profile_detail_view.dart)
- A bottom-sheet or full-screen view for profile details with smooth transitions.

---

### Offline Resilience

#### [main.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/main.dart)
- Initialize `LocalCacheService` and `NetworkSyncEngine` at startup.

#### [mock_data.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/core/utils/mock_data.dart)
- Update `syncProfilesFromDatabase` to save profiles to `LocalCacheService` (Hive).
- Load cached profiles as a fallback when `Supabase` fetch fails.

#### [local_cache_service.dart](file:///C:/Users/USER/Downloads/kurichiyar%20matrimony/lib/core/services/local_cache_service.dart)
- Add methods to cache `UserProfile` objects and retrieve them.
- Ensure `currentUser` is also cached for persistent sessions.

---

## Verification Plan

### Automated Tests
- `flutter build apk --debug`: Verify the build passes with new dependencies (`flutter_animate`, `hive`).

### Manual Verification
- **Offline Flow**: Disable Wi-Fi/Data and open the app; previously loaded profiles should still appear.
- **Sync Test**: Like a profile while offline, then re-enable network and verify the "Like" is persisted to Supabase.
- **UI Smoothness**: Observe the fade-in of cards and the smooth slide-up of the profile detail view.
