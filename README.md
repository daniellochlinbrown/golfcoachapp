# Golf Coach App - Learning Reference

## Project Overview

This is a Rails 8.1.1 web application that helps golfers improve their game by:
1. Calculating handicaps from golf round scores using the World Handicap System (WHS)
2. Generating personalized AI-powered training plans using Claude AI
3. Tracking progress over time

## Tech Stack

- **Framework**: Ruby on Rails 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: PostgreSQL
- **Styling**: Tailwind CSS
- **JavaScript**: Turbo (Hotwire) for SPA-like interactions
- **AI Integration**: Anthropic Claude API (via HTTParty)
- **Authentication**: Custom session-based authentication (bcrypt for password hashing)

## Application Architecture

### MVC Pattern (Model-View-Controller)

This app follows the standard Rails MVC architecture:

```
app/
├── models/          # Database models and business logic
├── views/           # HTML templates (ERB)
├── controllers/     # Request handlers
└── services/        # Business logic extraction (Service Objects pattern)
```

## Database Models

### User Model (`app/models/user.rb`)
- Handles user authentication and associations
- **Validations**: Email uniqueness, password presence
- **Associations**:
  - `has_many :golf_rounds` - A user can have multiple golf rounds
  - `has_many :training_plans` - A user can have multiple training plans
  - `has_many :handicap_calculations` - A user can have multiple handicap calculations
- **Security**: Uses `has_secure_password` (bcrypt) for password hashing

### GolfRound Model (`app/models/golf_round.rb`)
- Stores individual golf round data
- **Fields**:
  - `course_name` - Name of the golf course
  - `score` - Player's score for the round
  - `course_rating` - Difficulty rating (60-80)
  - `slope_rating` - Course difficulty slope (55-155)
  - `played_at` - Date the round was played
- **Associations**:
  - `belongs_to :user`
  - `has_and_belongs_to_many :handicap_calculations` (join table: `golf_rounds_handicap_calculations`)

### HandicapCalculation Model (`app/models/handicap_calculation.rb`)
- Stores calculated handicap data with AI context
- **Fields**:
  - `calculated_handicap` - The computed handicap index
  - `calculation_method` - How it was calculated (e.g., 'predicted')
  - `ai_context` - AI-generated explanation from Claude
- **Associations**:
  - `belongs_to :user`
  - `has_and_belongs_to_many :golf_rounds`
  - `has_many :training_plans`

### TrainingPlan Model (`app/models/training_plan.rb`)
- Stores AI-generated training plans at three complexity levels
- **Fields**:
  - `current_handicap` - Starting handicap
  - `target_handicap` - Goal handicap
  - `timeline_months` - Timeframe for improvement
  - `simple_guide` - Quick start guide (300-400 words)
  - `medium_guide` - Complete plan (600-800 words)
  - `complex_guide` - Advanced plan (1000-1500 words)
- **Associations**:
  - `belongs_to :user`
  - `belongs_to :handicap_calculation` (optional)

## Controllers

### ApplicationController (`app/controllers/application_controller.rb`)
- Base controller that all others inherit from
- **Key Methods**:
  - `current_user` - Returns logged-in user (memoized with `||=`)
  - `logged_in?` - Boolean check for authentication
  - `require_login` - Before action to protect routes

### SessionsController (`app/controllers/sessions_controller.rb`)
- Handles user login/logout
- **Actions**:
  - `new` - Shows login form
  - `create` - Authenticates user, creates session
  - `destroy` - Logs out user, clears session

### UsersController (`app/controllers/users_controller.rb`)
- Manages user registration and profiles
- **Actions**:
  - `new` - Registration form
  - `create` - Creates new user account
  - `show` - User dashboard with statistics

### GolfRoundsController (`app/controllers/golf_rounds_controller.rb`)
- Manages golf round entry
- **Key Concepts Demonstrated**:
  - **Strong Parameters**: Hash params converted to array with `.values`
  - **Validation**: Ensures exactly 3 rounds are submitted
  - **Transaction Safety**: Validates before saving all records
  - **Session Storage**: Stores round IDs for next step
  - **Error Handling**: Aggregates validation errors

**Important Bug Fix**: The form sends params as a hash `{"0" => {...}, "1" => {...}, "2" => {...}}`, not an array. Must use `.values` to convert to array before checking length.

### HandicapCalculationsController (`app/controllers/handicap_calculations_controller.rb`)
- Calculates handicaps and generates AI context
- **Flow**:
  1. Retrieves golf rounds from session
  2. Calls `HandicapCalculatorService` to compute handicap
  3. Creates `HandicapCalculation` record
  4. Calls `ClaudeApiService` to generate AI explanation
  5. Handles errors gracefully with fallback text

### TrainingPlansController (`app/controllers/training_plans_controller.rb`)
- Generates AI-powered training plans
- **Actions**:
  - `new` - Shows form to enter current/target handicap
  - `create` - Calls Claude API to generate three-tier plan
  - `show` - Displays plan with tabbed interface
  - `index` - Lists all user's training plans

## Service Objects Pattern

Service objects extract complex business logic from controllers, making code more maintainable and testable.

### HandicapCalculatorService (`app/services/handicap_calculator_service.rb`)
- **Purpose**: Implements World Handicap System calculation
- **Input**: Array of 3 GolfRound objects
- **Process**:
  1. Calculates differential for each round: `(score - course_rating) × (113 / slope_rating)`
  2. Averages the differentials
  3. Applies the 0.96 multiplier (WHS standard)
- **Output**: Calculated handicap index as float

### ClaudeApiService (`app/services/claude_api_service.rb`)
- **Purpose**: Interacts with Anthropic Claude API
- **Pattern**: HTTParty for HTTP requests
- **Key Methods**:
  - `generate_training_plan(current, target, months)` - Creates 3-tier training plan
  - `generate_handicap_context(rounds, handicap)` - Explains handicap calculation
- **Configuration**:
  - Model: `claude-sonnet-4-20250514`
  - Timeout: 120 seconds
  - Max tokens: 4096
  - API version: `2023-06-01`

**AI Prompt Engineering**:
- Uses section markers (`=== QUICK START GUIDE ===`) for structured output
- Parser extracts sections with regex
- Handles missing sections gracefully

## Key Rails Concepts Demonstrated

### 1. RESTful Routes
```ruby
resources :users, only: [:new, :create, :show]
resources :golf_rounds, only: [:new, :create, :index]
resources :training_plans, only: [:new, :create, :show, :index]
```

### 2. Session Management
```ruby
session[:user_id] = user.id          # Store user ID
session[:golf_round_ids] = [1,2,3]   # Store temporary data
session.delete(:user_id)              # Clear session on logout
```

### 3. Associations & Joins
```ruby
# Has-many-through relationship
user.golf_rounds                      # All rounds for user
handicap.golf_rounds                  # Rounds used in calculation

# Join table (HABTM - Has And Belongs To Many)
# Table: golf_rounds_handicap_calculations
# Columns: golf_round_id, handicap_calculation_id
```

### 4. Validations
```ruby
validates :email, presence: true, uniqueness: true
validates :score, numericality: { greater_than: 0 }
```

### 5. Callbacks & Lifecycle Hooks
```ruby
before_action :require_login          # Run before controller actions
has_secure_password                   # Adds password validation
```

### 6. Error Handling
```ruby
begin
  claude_service.generate_training_plan(...)
rescue => e
  Rails.logger.error("Error: #{e.message}")
  flash[:alert] = "Something went wrong"
end
```

### 7. Strong Parameters
```ruby
# Rails 7+ allows hash params
params.require(:training_plan).permit(:current_handicap, :target_handicap)

# For nested hashes, use .values to convert to array
rounds_array = params[:rounds].values
```

### 8. Partials & Layouts
```ruby
# layouts/application.html.erb - Main layout wrapper
# Partials use underscore: _form.html.erb
<%= render 'shared/navbar' %>
```

### 9. Database Migrations
```ruby
rails generate migration CreateUsers email:string password_digest:string
rails db:migrate                      # Run migrations
rails db:rollback                     # Undo last migration
```

## Application Flow

### User Journey: Calculate Handicap & Get Training Plan

1. **Sign Up / Login**
   - `SessionsController#create`
   - Sets `session[:user_id]`

2. **Enter 3 Golf Rounds**
   - `GolfRoundsController#new` - Shows form
   - `GolfRoundsController#create` - Validates & saves rounds
   - Stores `session[:golf_round_ids]`
   - Redirects to handicap calculation

3. **Calculate Handicap**
   - `HandicapCalculationsController#new`
   - Retrieves rounds from session
   - Calls `HandicapCalculatorService.calculate`
   - Calls `ClaudeApiService.generate_handicap_context`
   - Saves `HandicapCalculation`
   - Shows result with AI explanation

4. **Generate Training Plan**
   - User clicks "Create Training Plan"
   - `TrainingPlansController#new` - Shows form
   - User enters current/target handicap and timeline
   - `TrainingPlansController#create`:
     - Calls `ClaudeApiService.generate_training_plan`
     - Parses response into 3 guides (simple/medium/complex)
     - Saves `TrainingPlan`
   - `TrainingPlansController#show` - Displays with tabs

5. **View Dashboard**
   - `UsersController#show`
   - Shows training plan count, recent plans, rounds

## Views & Frontend

### Tailwind CSS Styling
- Utility-first CSS framework
- Classes like `bg-blue-600`, `text-white`, `rounded-lg`
- Responsive with `md:` and `lg:` prefixes

### ERB Templates (Embedded Ruby)
```erb
<% # Ruby code (not output) %>
<%= # Ruby code with output %>
<%= link_to "Text", path, class: "..." %>
<%= form_with model: @user do |f| %>
```

### Turbo (Hotwire)
- SPA-like navigation without writing JavaScript
- Form submissions use Turbo Streams
- `data-turbo="false"` to opt out

## Environment Setup

### Environment Variables
```bash
# .env (not in git)
CLAUDE_API_KEY=your_api_key_here
DATABASE_URL=postgresql://...
```

### Running the App Locally
```bash
bundle install                # Install gems
rails db:create db:migrate    # Setup database
rails server                  # Start server (port 3000)
```

## Deployment

This app is configured to deploy to **Render** (a modern cloud platform with free tier).

**Quick Start:**
1. Check deployment readiness: `bin/check_deploy_readiness`
2. Follow the guide: **[RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)**
3. Deploy in under 10 minutes with automatic SSL and managed PostgreSQL

See [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) for complete deployment instructions.

## Common Rails Commands

```bash
# Database
rails db:migrate              # Run pending migrations
rails db:seed                 # Load seed data
rails db:reset                # Drop, create, migrate, seed

# Console
rails console                 # Interactive Ruby shell
rails dbconsole               # Database shell

# Generators
rails generate model User email:string
rails generate controller Users new create
rails generate migration AddFieldToTable field:type

# Testing
rails test                    # Run all tests
rails test:system             # Run system tests
```

## Learning Resources for Ruby on Rails

### Key Concepts to Study
1. **Active Record** - Rails ORM for database interactions
2. **Routing** - URL patterns to controller actions
3. **Migrations** - Version control for database schema
4. **Associations** - Relationships between models
5. **Validations** - Data integrity rules
6. **Callbacks** - Hooks into model lifecycle
7. **Service Objects** - Extracting business logic
8. **Sessions** - Maintaining state across requests
9. **Strong Parameters** - Security for mass assignment
10. **RESTful Design** - Standard CRUD operations

### Recommended Documentation
- Rails Guides: https://guides.rubyonrails.org/
- Active Record: https://guides.rubyonrails.org/active_record_basics.html
- Rails Routing: https://guides.rubyonrails.org/routing.html

## Code Examples for ChatGPT Questions

When asking ChatGPT for help, you can reference:

**Example 1: "Explain the association between User and TrainingPlan"**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :training_plans
end

# app/models/training_plan.rb
class TrainingPlan < ApplicationRecord
  belongs_to :user
end
```

**Example 2: "How does the golf rounds controller validate 3 rounds?"**
```ruby
# app/controllers/golf_rounds_controller.rb
rounds_params = params[:rounds] || {}
rounds_array = rounds_params.values  # Convert hash to array

if rounds_array.length != 3
  flash.now[:alert] = "Please enter exactly 3 rounds of golf."
  render :new, status: :unprocessable_entity
  return
end
```

**Example 3: "How does the handicap calculation work?"**
```ruby
# app/services/handicap_calculator_service.rb
def calculate
  differentials = @golf_rounds.map do |round|
    (round.score - round.course_rating) * (113.0 / round.slope_rating)
  end
  average_differential = differentials.sum / differentials.size.to_f
  (average_differential * 0.96).round(1)
end
```

## Project Structure

```
golfcoachapp/
├── app/
│   ├── controllers/          # Request handlers
│   │   ├── application_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── users_controller.rb
│   │   ├── golf_rounds_controller.rb
│   │   ├── handicap_calculations_controller.rb
│   │   └── training_plans_controller.rb
│   ├── models/              # Database models
│   │   ├── user.rb
│   │   ├── golf_round.rb
│   │   ├── handicap_calculation.rb
│   │   └── training_plan.rb
│   ├── services/            # Business logic
│   │   ├── claude_api_service.rb
│   │   └── handicap_calculator_service.rb
│   └── views/               # HTML templates
│       ├── layouts/
│       │   └── application.html.erb
│       ├── home/
│       ├── sessions/
│       ├── users/
│       ├── golf_rounds/
│       ├── handicap_calculations/
│       └── training_plans/
├── config/
│   ├── routes.rb            # URL routing
│   └── database.yml         # DB configuration
├── db/
│   ├── migrate/             # Database migrations
│   └── schema.rb            # Current database structure
└── Gemfile                  # Ruby dependencies

```

## Questions to Ask ChatGPT

Use this README as context and ask questions like:

1. "Based on this Golf Coach App, explain how Rails associations work with has_many and belongs_to"
2. "In the GolfRoundsController, why do we need to convert the params hash to an array?"
3. "How does the session-based authentication work in this app?"
4. "Explain the Service Object pattern used in ClaudeApiService"
5. "What is the difference between `render` and `redirect_to` in Rails?"
6. "How does the World Handicap System calculation work in HandicapCalculatorService?"
7. "Why is bcrypt used for password storage instead of storing plain text?"
8. "What is the purpose of the join table golf_rounds_handicap_calculations?"

## Contributing & Learning Path

1. Start by reading through the models to understand data structure
2. Follow a single user flow from controller to view
3. Experiment with rails console to query data
4. Try adding a new feature (e.g., editing a golf round)
5. Study the service objects to understand business logic extraction

---

**Happy Learning!** This app demonstrates many intermediate Rails concepts and is a great reference for building modern Rails applications.
