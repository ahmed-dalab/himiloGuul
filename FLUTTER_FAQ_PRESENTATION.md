# Flutter – Most Asked Questions (HimiloGuul App)

This document explains the most commonly asked Flutter concepts **as used in the HimiloGuul app**, for your presentation. Every concept is explained with how it appears in this project.

---

## 1. What is Flutter and why use it in this app?

**Flutter** is Google’s UI toolkit for building **cross-platform** apps from a **single codebase**. You write Dart code once and run it on:

- **Android**
- **iOS**
- **Web**
- **Windows / macOS / Linux** (desktop)

**In HimiloGuul:** The entire mobile/web frontend lives in the `frontend/` folder. One Flutter app serves buyers (browse businesses), sellers (my businesses, contacts), and admins (users, roles, permissions, menus). No separate Android and iOS codebases—one `lib/` tree for all platforms.

---

## 2. What is the difference between StatelessWidget and StatefulWidget?

- **StatelessWidget:** A widget that **does not change** over time. It only depends on its constructor arguments and the current `BuildContext`. Examples: `WelcomeScreen`, `FeatureIllustration`, simple text or icon widgets.
- **StatefulWidget:** A widget that **can change** over time. It has an associated `State` object that holds mutable data and can call `setState()` to trigger a rebuild. Examples: `LoginScreen`, `AdminLayout`, `BusinessDetailScreen`, `BrowseBusinessScreen`.

**In the app:**

- `WelcomeScreen` is **StatelessWidget**—static welcome content, no form or changing index.
- `AdminLayout` is **StatefulWidget**—it keeps `_selectedIndex` for the bottom navigation tab and updates it when the user taps a tab.

```dart
// StatelessWidget – no internal state
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) { ... }
}

// StatefulWidget – has mutable state (_selectedIndex)
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});
  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}
class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  ...
}
```

---

## 3. What is State Management and how does Provider work here?

**State management** is how you keep and update **app-wide or screen-wide data** (e.g. logged-in user, list of businesses) and how the UI **reacts** when that data changes.

**In HimiloGuul we use the `provider` package:**

- **AuthProvider:** Holds current user, token, menus; handles login/logout and session restore.
- **BusinessProvider:** Holds list of businesses, selected business, loading and error; handles fetch by ID and browse.

**Concepts:**

- **ChangeNotifier:** A class that notifies listeners when something changes (e.g. after login or after fetching businesses). Both `AuthProvider` and `BusinessProvider` extend/mix `ChangeNotifier` and call `notifyListeners()` after updating data.
- **MultiProvider:** At the root (`main.dart`) we register both providers so any descendant widget can access them.
- **context.read\<T>():** Gets the provider **once** (e.g. to call `login()` or `fetchBusinesses()`). Use when you only need to **trigger an action**, not rebuild when data changes.
- **context.watch\<T>():** Listens to the provider and **rebuilds the widget** when it notifies. Used in `AdminLayout` for `AuthProvider` so the UI updates when user or menus change.
- **Consumer\<T>:** Same idea as `watch` but scoped to a part of the tree. In `BusinessDetailScreen` we use `Consumer<BusinessProvider>` so only that subtree rebuilds when loading/error/business changes.

```dart
// main.dart – register providers
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => BusinessProvider()),
    ChangeNotifierProvider.value(value: auth),
  ],
  child: MaterialApp.router(...),
)

// Read once (e.g. in button onPressed)
final authProvider = context.read<AuthProvider>();
await authProvider.login(email, password);

// Rebuild when AuthProvider changes
final authProvider = context.watch<AuthProvider>();
final adminMenus = authProvider.adminMenus;

// Rebuild only the Consumer part when BusinessProvider changes
Consumer<BusinessProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) return CircularProgressIndicator();
    ...
  },
)
```

---

## 4. How does Navigation work? What is go_router?

**Navigation** is moving between screens (routes). HimiloGuul uses **go_router** (declarative routing) instead of the older Navigator 1.0 (imperative push/pop).

**Concepts:**

- **Routes** are defined in one place (`app_router.dart`): path → screen. Example: `/login` → `LoginScreen`, `/admin` → `AdminLayout`.
- **GoRouter** is created with `initialLocation`, `routes`, `redirect`, and optionally `refreshListenable` (e.g. `AuthProvider` so redirects run again when auth state changes).
- **Redirect:** Before showing a route, GoRouter runs a `redirect` callback. We use it to:
  - Send logged-in users away from `/`, `/login`, `/register` to `/admin`, `/seller`, or `/browse-business` by role.
  - Send logged-out users from `/admin`, `/seller`, `/create-business` to `/` (welcome).
- **context.go(path):** Replaces the entire stack with that path (e.g. after login: `context.go('/admin')`).
- **context.push(path):** Pushes a new route on top (e.g. go to register from login).
- **context.pop():** Pops the current route.
- **Path parameters:** Routes like `/business-detail/:id` and `/admin/business/:id` get `id` from `state.pathParameters['id']`.
- **Extra data:** You can pass a map with `context.push(path, extra: {...})` and read it in the route builder as `state.extra`.

**In the app:** After login we call `context.go('/admin')` or `context.go('/seller')`; from business detail we `context.push('.../contact', extra: {...})` to open the contact form with business info.

---

## 5. What are App Routes and why use constants?

**AppRoutes** (`app_routes.dart`) is a class full of **route path constants** (e.g. `AppRoutes.welcome`, `AppRoutes.login`, `AppRoutes.businessDetail`).

**Why use them:**

- Avoid typos (e.g. `/browse-bussiness`).
- One place to change a path; all usages stay correct.
- Easier refactors and search.

**In the app:** We use `AppRoutes.welcome`, `AppRoutes.login`, `AppRoutes.browseBusiness`, `AppRoutes.businessDetail`, etc., in both `app_router.dart` and in screens (e.g. `context.push(AppRoutes.register)`).

---

## 6. How do Forms and Validation work?

Flutter uses **Form** and **FormField** widgets for forms and validation.

**Concepts:**

- **Form:** Wraps a set of form fields and holds a **FormState** (via `GlobalKey<FormState>`).
- **GlobalKey<FormState>:** Lets you call `_formKey.currentState!.validate()` and `save()` from outside the Form.
- **TextFormField:** A text field that can be validated. You pass:
  - **controller:** `TextEditingController` for reading/writing value (remember to `dispose()` in `State.dispose()`).
  - **validator:** Function that returns an error string if invalid, or `null` if valid.
  - **decoration:** Hint, border, fill color, etc.

**In the app:** `LoginScreen` has a `Form` with `_formKey`. On “Sign In” we call `_formKey.currentState!.validate()`. If valid, we read `_emailController.text` and `_passwordController.text` and call `authProvider.login(...)`. Validators check non-empty and email format.

---

## 7. What is Theme and how is it set up?

**Theme** defines global look: colors, text styles, button shapes, etc. So you don’t repeat the same colors and styles in every screen.

**In HimiloGuul:**

- **AppColors** (`app_colors.dart`): Central place for color constants (e.g. `primaryBlue`, `darkGray`, `white`). Used in themes and in widgets.
- **AppTheme** (`app_theme.dart`): Builds a `ThemeData` with:
  - **useMaterial3: true**
  - **colorScheme:** primary, surface, onSurface from `AppColors`
  - **scaffoldBackgroundColor**, **fontFamily**
- **MaterialApp.router** gets `theme: AppTheme.lightTheme`. All descendant widgets can use `Theme.of(context)` or direct `AppColors` where we want consistency.

---

## 8. What are the main Layout widgets used?

- **Scaffold:** Base “page” layout: app bar, body, bottom nav, drawer, FAB. Almost every screen is a `Scaffold`.
- **Column / Row:** Linear layout of children (vertical / horizontal). We use them for stacking widgets (e.g. form fields, header + list).
- **Expanded:** Inside Column/Row, makes a child take remaining space. Example: WelcomeScreen uses `Expanded(flex: 30)` and `Expanded(flex: 70)` to split header and content.
- **ListView:** Scrollable list of children. Used in drawer menu and in browse list.
- **SingleChildScrollView:** One scrollable child (e.g. long form or business detail body).
- **Padding / SizedBox:** Spacing and sizing. `SizedBox(height: 24)` between form fields; `Padding(padding: EdgeInsets.all(24))` around content.

**In the app:** Admin layout uses `Scaffold` with `appBar`, `drawer`, `body`, and `bottomNavigationBar`. Login and business detail use `SingleChildScrollView` so content scrolls on small screens.

---

## 9. How do we do HTTP and API calls? What is Dio?

**Dart** uses **async/await** and **Future** for asynchronous work. Network calls are async.

**In HimiloGuul we use the Dio package** (not the built-in `http`):

- **Dio** is an HTTP client: GET, POST, PUT, DELETE, interceptors, form data, file upload.
- **AuthService** and **BusinessService** create a `Dio` instance and call `_dio.get()`, `_dio.post()`, etc., with `ApiConstants.baseUrl`.
- **Authorization:** For protected endpoints we pass `Options(headers: {'Authorization': 'Bearer $token'})`.
- **Error handling:** We use `on DioException catch (e)` and throw user-friendly `Exception` messages; sometimes we read `e.response?.data['message']`.
- **FormData / MultipartFile:** For creating/updating business with images we use `FormData` and `MultipartFile.fromFile()` and send with `_dio.post(..., data: formData)`.

**Flow:** UI calls a method on a **Provider** (e.g. `authProvider.login()`); the provider calls a **Service** (e.g. `AuthService.login()`); the service uses **Dio** to hit the backend. So: **Screen → Provider → Service → Dio → API.**

---

## 10. What are Models and fromJson?

**Models** are Dart classes that represent API or app data (e.g. User, Business, AppMenu).

**Concepts:**

- **Immutable fields:** Often `final String id`, etc., set via constructor.
- **fromJson:** A **factory** constructor that takes `Map<String, dynamic>` (JSON) and returns an instance. Used after we get `response.data` from Dio.
- **Enums:** For a fixed set of values (e.g. `UserRole.admin`, `UserRole.seller`, `UserRole.buyer`). Backend often sends a string; we map it to the enum in the provider or in the model.

**In the app:** `User` has `id`, `name`, `email`, `role` (enum). `Business` has many fields and a `factory Business.fromJson(Map<String, dynamic> json)`. AuthProvider parses the login response and builds a `User`; BusinessProvider uses `Business.fromJson(response['data'])` to build a `Business`.

---

## 11. How is Local / Secure Storage used?

We need to **persist** token and user so that after app restart the user stays logged in.

**In HimiloGuul:**

- **flutter_secure_storage:** Stores the **auth token** securely (encrypted). Used in `AuthStorageService` with keys like `auth_token`.
- **shared_preferences:** Stores simple key-value data. We store **user info** (id, name, email, role) as a JSON string so we can restore the session without calling the API first.
- **AuthStorageService** wraps both: `saveToken`, `getToken`, `saveUser`, `getUser`, `clear`. After login we call `saveToken` and `saveUser`; on logout we call `clear`. On app start, `AuthProvider.ensureRestored()` reads from storage and restores `_currentUser` and `_token`, then loads menus if needed.

---

## 12. What is CustomPainter?

**CustomPainter** lets you draw custom graphics on a **Canvas** (shapes, paths, etc.) instead of using only built-in widgets.

**In the app:** `AbstractHeaderPainter` extends `CustomPainter` and in `paint()` draws circles with `canvas.drawCircle()` and colors from `AppColors`. We use it on the welcome screen inside a `CustomPaint(painter: AbstractHeaderPainter())` so the header has a custom abstract graphic. `shouldRepaint` returns false because the graphic is static.

---

## 13. What is the Widget lifecycle? initState, dispose, mounted?

For **StatefulWidget**:

- **initState():** Called once when the State is inserted into the tree. Use for one-time setup (e.g. start loading data). In the app we use `Future.microtask(() { ... context.read<BusinessProvider>().fetchBusinessById(...); })` so the first frame is built before we use `context`.
- **dispose():** Called when the State is removed. Use to release resources: `_emailController.dispose()`, `_searchController.dispose()`, etc. Never use `context` after disposal.
- **mounted:** Boolean that is true while the widget is in the tree. After an async gap (e.g. after `await authProvider.login()`), always check `if (mounted)` before calling `setState` or `context.go`, otherwise you might call setState on a disposed widget.

**In the app:** LoginScreen disposes its controllers in `dispose()`. After `await authProvider.login()` we check `if (success && mounted)` before updating state and navigating.

---

## 14. What is BuildContext and when to use read vs watch?

**BuildContext** is the handle to the current position in the widget tree. It’s used for:

- Finding **inherited** things: `Theme.of(context)`, `MediaQuery.of(context)`, and **Provider:** `context.read<AuthProvider>()`, `context.watch<AuthProvider>()`.
- **Navigation:** `context.go()`, `context.push()`, `context.pop()` (from go_router).
- **Overlays:** `ScaffoldMessenger.of(context).showSnackBar(...)`, `showDialog(context: context, ...)`.

**read vs watch:**

- **context.read\<T>():** Get the provider once. Use in callbacks (onPressed, initState via microtask) when you only need to **call a method** and don’t need the widget to rebuild when that provider changes.
- **context.watch\<T>():** Subscribe to the provider. The widget **rebuilds** when `notifyListeners()` is called. Use when the UI depends on the provider’s current value (e.g. admin menus, loading state).

**In the app:** In login we use `context.read<AuthProvider>()` to call `login()`. In AdminLayout we use `context.watch<AuthProvider>()` so the layout rebuilds when menus or user change.

---

## 15. What are Keys (key, super.key, GlobalKey)?

**key** helps Flutter identify a widget when the tree structure or order changes so it can preserve state or match elements correctly.

- **super.key:** Passes the optional `key` argument to the base class. Used in widget constructors: `const WelcomeScreen({super.key})`.
- **GlobalKey:** A key that is unique across the whole app. We use **GlobalKey<FormState>** so we can call `_formKey.currentState!.validate()` from outside the Form widget.

**In the app:** We use `final _formKey = GlobalKey<FormState>();` in LoginScreen and assign it to `Form(key: _formKey)`.

---

## 16. MaterialApp.router vs MaterialApp?

- **MaterialApp:** Classic Flutter entry. You pass `routes` and `onGenerateRoute` or use Navigator directly.
- **MaterialApp.router:** Uses a **router** (e.g. GoRouter) for navigation. You pass `routerConfig: GoRouter(...)` and optionally `routeInformationProvider` for web. No `routes` map on MaterialApp.

**In the app:** We use `MaterialApp.router` with `routerConfig: AppRouter.createRouter(auth)` so all navigation is declarative and we get redirects and path parameters from go_router.

---

## 17. What is MultiProvider and why at the root?

**MultiProvider** registers multiple providers at once so any descendant can access them with `context.read` or `context.watch`.

**Why at root:** So that **AuthProvider** and **BusinessProvider** are available everywhere: login screen, admin layout, business screens, etc. We put it in `main.dart` as the parent of `MaterialApp.router`, so the whole app has access.

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => BusinessProvider()),
    ChangeNotifierProvider.value(value: auth),
  ],
  child: MaterialApp.router(...),
)
```

We use `ChangeNotifierProvider.value(value: auth)` for AuthProvider because we create it in `main()` and pass it in so the same instance is used for the router’s `refreshListenable` and for the app.

---

## 18. Consumer vs context.watch?

- **context.watch\<T>():** The **whole** widget’s `build` runs again when the provider notifies. If the widget is large, everything below rebuilds.
- **Consumer\<T>:** Only the **builder** of Consumer rebuilds when the provider notifies. The rest of the tree above and beside it does not.

**In the app:** In BusinessDetailScreen we use `Consumer<BusinessProvider>` so only the body (loading / error / business content) rebuilds when the provider updates, not the whole Scaffold and app bar.

---

## 19. How are Images used (network and picker)?

- **Image.network(url):** Loads an image from a URL. We use it for business images from the API. We set `fit: BoxFit.cover` and use `errorBuilder` to show a placeholder icon if the load fails.
- **image_picker:** For picking from gallery/camera when creating or editing a business. We use `ImagePicker().pickMultiImage()` (or similar) and get `XFile` objects, then send them as `MultipartFile` in Dio’s FormData.

**In the app:** Business detail shows `business.images.first.url` with `Image.network`. Create business screen uses image_picker and BusinessService passes `List<XFile>? imageFiles` to upload with the form.

---

## 20. How do Dialogs and SnackBars work?

- **showDialog:** Displays a route on top of the current one. We use `showDialog(context: context, builder: (ctx) => AlertDialog(...))`. The builder returns an **AlertDialog** with title, content, and actions (e.g. Cancel / Log out). `Navigator.of(ctx).pop(true)` closes it and returns a value; we `await showDialog<bool>()` and then logout and navigate if the user confirmed.
- **SnackBar:** Short message at the bottom. We use `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('...')))` for errors (e.g. “Login failed”) or feedback (e.g. “This business has no seller assigned”).

**In the app:** Admin layout calls `_showLogoutConfirm()` which uses `showDialog` with an AlertDialog; on confirm we call `authProvider.logout()` and `context.go(AppRoutes.welcome)`. Login screen shows a SnackBar on login failure.

---

## 21. What is in pubspec.yaml and why?

**pubspec.yaml** defines the **project** (name, version, SDK) and **dependencies**.

**In HimiloGuul we use:**

- **flutter** (SDK): Core framework.
- **cupertino_icons:** iOS-style icons.
- **provider:** State management (ChangeNotifier, MultiProvider, read/watch).
- **dio:** HTTP client for API calls.
- **go_router:** Declarative routing and redirects.
- **shared_preferences:** Simple key-value storage (user data).
- **flutter_secure_storage:** Secure storage (token).
- **image_picker:** Pick images from device for business uploads.

After changing `pubspec.yaml`, you run **`flutter pub get`** to download packages. Assets (e.g. `assets/images/`) are also declared under `flutter:`.

---

## 22. What are Enums and how are they used?

**Enums** define a fixed set of named values. Type-safe and readable.

**In the app:** `UserRole` is an enum: `admin`, `seller`, `buyer`. The backend sends a string (e.g. `"admin"`); in AuthProvider we do `if (lowerRole == 'admin') role = UserRole.admin` and then store `User(..., role: role)`. Later we use `user.role == UserRole.admin` to decide redirects and which layout to show.

---

## 23. Async/Await and Future in Flutter

**Future** represents a value that will be available later (e.g. result of an HTTP call). **async/await** lets you write sequential-looking code that waits for Futures without blocking the UI.

- **async:** Marks a function that returns a Future.
- **await:** Pauses the function until the Future completes; the result is the value.
- **try/catch:** Use around await to handle errors (e.g. network or API errors).

**In the app:** All service methods are `Future<...>` and we await them in providers (e.g. `await _authService.login(...)`). In the UI we call provider methods (which are async) and use try/catch; we check `mounted` after await before setState or navigation.

---

## 24. Null Safety and Optional Types

Dart is **null-safe**: variables are non-nullable by default. You must mark nullable types with `?` and handle null (e.g. `user?.name`, `value ?? 'default'`).

**In the app:** We use `User? _currentUser`, `String? _token`, `String? _error`, and optional parameters like `String? category`. We use `business?.ownerId`, `extra?['businessName']`, and `userMap['role'] as String?` when reading from JSON or route extra.

---

## 25. Why use Future.microtask in initState?

You **cannot** use `context.read` (or other inherited widget access) **directly** in `initState` for some setups, because the widget might not be fully attached. Also, doing heavy work synchronously in initState can delay the first frame.

**Future.microtask(() { ... })** schedules the callback right after the current event loop, so:

- The first frame is built and the widget is in the tree (context is valid).
- We can safely call `context.read<BusinessProvider>().fetchBusinessById(widget.businessId)` and trigger the load without blocking build.

**In the app:** Both `BusinessDetailScreen` and `BrowseBusinessScreen` use `Future.microtask` in `initState` to start loading data from the provider.

---

## 26. What is refreshListenable in GoRouter?

**refreshListenable** is a Listenable (e.g. ChangeNotifier) that GoRouter listens to. When it notifies (e.g. after login or logout), GoRouter **re-runs the redirect** logic. So when auth state changes, the app can send the user to the correct route (e.g. from login to `/admin`) or to welcome if they log out.

**In the app:** We pass `refreshListenable: authProvider` so that when we call `authProvider.login()` or `authProvider.logout()` and `notifyListeners()`, the router redirect runs again and the URL/stack updates accordingly.

---

## 27. Summary Table (Concepts in This App)

| Concept              | Where / how in HimiloGuul                                      |
|----------------------|----------------------------------------------------------------|
| StatelessWidget      | WelcomeScreen, feature sections, static widgets               |
| StatefulWidget       | LoginScreen, AdminLayout, BusinessDetailScreen, BrowseBusiness |
| Provider             | AuthProvider, BusinessProvider; MultiProvider in main          |
| go_router            | app_router.dart; redirect by role; path params and extra      |
| Form + validation    | LoginScreen: Form, TextFormField, GlobalKey<FormState>         |
| Theme / colors       | AppTheme, AppColors; MaterialApp.router theme                  |
| Layout               | Scaffold, Column, Row, Expanded, ListView, SingleChildScrollView |
| HTTP                 | Dio in AuthService, BusinessService; FormData for images      |
| Models               | User, Business, AppMenu; fromJson, enums                      |
| Storage              | AuthStorageService: FlutterSecureStorage + SharedPreferences   |
| CustomPainter        | AbstractHeaderPainter on welcome screen                       |
| Lifecycle            | initState (microtask fetch), dispose (controllers), mounted   |
| read vs watch        | read in callbacks; watch in AdminLayout; Consumer in detail   |
| Keys                 | super.key on widgets; GlobalKey<FormState>                    |
| Images               | Image.network for API images; image_picker for uploads        |
| Dialogs / SnackBar   | Logout confirmation dialog; login error SnackBar               |

---

Use this document as your single reference for “most asked Flutter questions” in the HimiloGuul app during your presentation. Every answer is tied to how the app actually implements the concept.
