## ADDED Requirements

### Requirement: Authentication Scaffold Is Generated

The system SHALL include the Rails 8 built-in authentication scaffold (User model, Session model, sign-in/sign-out controllers, password reset mailer) so that subsequent changes can require login without re-deciding auth.

#### Scenario: Auth models exist
- **WHEN** a contributor inspects `app/models/`
- **THEN** `user.rb` and `session.rb` files exist with the contents produced by `bin/rails generate authentication`

#### Scenario: Auth routes are wired
- **WHEN** a contributor runs `bin/rails routes`
- **THEN** the output includes named routes for sessions (`new_session`, `session`), passwords (`new_password`, `edit_password`), and a sign-out path

### Requirement: Password Storage Is Secure

The system SHALL store user passwords using `has_secure_password` (bcrypt), never as plaintext.

#### Scenario: User model uses has_secure_password
- **WHEN** a contributor opens `app/models/user.rb`
- **THEN** the class declares `has_secure_password` and the `users` table has a `password_digest` column (not a `password` column)

#### Scenario: bcrypt is in the bundle
- **WHEN** a contributor inspects `Gemfile.lock`
- **THEN** `bcrypt` is present as a direct or transitive dependency of Rails authentication

### Requirement: Sign-In, Sign-Out, and Password Reset Flows Function

The system SHALL provide working sign-in, sign-out, and password-reset flows out of the box, exercised by tests.

#### Scenario: Successful sign-in
- **WHEN** a test creates a user and POSTs valid credentials to the session create route
- **THEN** the response sets a session cookie and redirects to a post-sign-in path

#### Scenario: Failed sign-in
- **WHEN** a test POSTs invalid credentials to the session create route
- **THEN** the response renders the new-session view with an error message and does not set an authenticated session

#### Scenario: Sign-out clears session
- **WHEN** an authenticated test session DELETEs the session route
- **THEN** the session cookie is cleared and subsequent requests are unauthenticated

#### Scenario: Password reset email is delivered
- **WHEN** a test requests a password reset for an existing user's email
- **THEN** an email is enqueued via ActionMailer's test adapter containing a single-use reset link

### Requirement: No Controllers Are Yet Gated

The system SHALL leave the placeholder home route publicly accessible in this change. Authentication exists, but no application controller requires it yet.

#### Scenario: Home page is public
- **WHEN** an unauthenticated client requests GET `/`
- **THEN** the response is HTTP 200 and renders the placeholder home view without redirecting to sign-in

### Requirement: No Default Users Are Seeded

The system SHALL NOT create a default admin or test user in `db/seeds.rb`. Future changes that introduce protected functionality will define their own seed strategy.

#### Scenario: Seeds are empty of users
- **WHEN** a contributor runs `bin/rails db:seed` on a fresh database
- **THEN** the `users` table contains zero rows
