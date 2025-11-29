# Golf Coach App - Technical Specification

## Overview
An educational golf training application that helps golfers create personalized training plans based on their current handicap, target handicap, and available timeline. The app leverages the Claude API to generate research-backed training recommendations at multiple complexity levels.

## Core Purpose
**Education-focused service** that provides golfers with structured, research-based guidance on how to improve their game through proper training schedules and techniques.

---

## User Flow

### Use Case 1: Registered Golfer with Official Handicap

#### 1. User Input
Users provide three key pieces of information:
- **Current Handicap**: Their present golf handicap (e.g., 18, 12, 5)
- **Target Handicap**: Their desired handicap goal (e.g., 10, 5, scratch)
- **Timeline**: How long they have to achieve their goal (e.g., 3 months, 6 months, 1 year)

#### 2. Training Plan Generation
The app processes this information through Claude API to generate:
- **Simple Guide**: Basic, easy-to-follow recommendations
- **Medium Guide**: Moderate depth with more specific techniques
- **Complex Guide**: Comprehensive, detailed training program

#### 3. Output
Present all three guides to the user, allowing them to choose the level of detail that suits their learning style and commitment level.

---

### Use Case 2: Non-Registered Golfer without Official Handicap

#### 1. Score Upload
Users who don't have an official handicap can:
- **Upload 54 Holes of Data**: Input scores from their last 3 rounds of golf
  - Round 1: Course name, score, course rating, slope rating
  - Round 2: Course name, score, course rating, slope rating
  - Round 3: Course name, score, course rating, slope rating

#### 2. Handicap Prediction
The app calculates an estimated handicap using:
- **Standard Handicap Formula**: Uses the World Handicap System (WHS) methodology
- **Claude API Enhancement**: Optionally uses Claude to validate and provide context about the predicted handicap
- Display the calculated handicap to the user with explanation

#### 3. Continue to Training Plan
Once handicap is predicted:
- **Target Handicap**: User inputs their desired handicap goal
- **Timeline**: User selects their timeframe
- System generates the same three-tier training guides as Use Case 1

#### 4. Output
Present predicted handicap, all three guides, and allow user to save their baseline for future reference.

---

## Technical Architecture

### Backend: Ruby on Rails
**Version**: Rails 7.x with Ruby 3.x

#### Models

```ruby
# User Model
- email (string, required)
- encrypted_password (string)
- has_official_handicap (boolean, default: false)
- created_at, updated_at

# GolfRound Model (NEW)
- user_id (foreign key, nullable for guest users)
- course_name (string)
- score (integer)
- course_rating (decimal)
- slope_rating (integer)
- played_at (date)
- created_at, updated_at

# HandicapCalculation Model (NEW)
- user_id (foreign key, nullable for guest users)
- calculated_handicap (decimal)
- calculation_method (string: 'official', 'predicted')
- golf_round_ids (array of integers, or separate join table)
- created_at, updated_at

# TrainingPlan Model
- user_id (foreign key, nullable for guest users)
- handicap_calculation_id (foreign key, optional)
- current_handicap (decimal)
- target_handicap (decimal)
- timeline_months (integer)
- simple_guide (text)
- medium_guide (text)
- complex_guide (text)
- created_at, updated_at
```

#### Controllers
- `SessionsController` - Handle login/logout
- `UsersController` - User registration and profile
- `GolfRoundsController` - Input and manage golf round scores (NEW)
- `HandicapCalculationsController` - Calculate predicted handicaps (NEW)
- `TrainingPlansController` - Create and display training plans
- `Api::ClaudeController` - Internal API wrapper for Claude calls

#### Services
- `ClaudeApiService` - Handle communication with Anthropic Claude API
- `HandicapCalculatorService` - Calculate handicap from golf rounds (NEW)
- `TrainingPlanGenerator` - Orchestrate plan generation logic

### Frontend
- **Views**: ERB templates with Hotwire (Turbo + Stimulus)
- **Styling**: Tailwind CSS or Bootstrap for responsive design
- **JavaScript**: Stimulus controllers for interactive elements
- **Multi-step Form**: For score input (3 rounds)

### Database
- **PostgreSQL** (recommended) or SQLite for development

---

## Handicap Calculation Logic

### World Handicap System (WHS) Formula

```ruby
# services/handicap_calculator_service.rb

class HandicapCalculatorService
  def initialize(golf_rounds)
    @golf_rounds = golf_rounds
  end

  def calculate
    # Step 1: Calculate Score Differential for each round
    # Score Differential = (113 / Slope Rating) × (Adjusted Gross Score − Course Rating)

    differentials = @golf_rounds.map do |round|
      (113.0 / round.slope_rating) * (round.score - round.course_rating)
    end

    # Step 2: For 3 rounds, use the lowest differential
    # For more rounds, use average of best differentials
    if differentials.length == 3
      lowest_differential = differentials.min
      handicap_index = lowest_differential - 2.0 # Adjustment for small sample
    else
      # Standard WHS: average of best differentials
      handicap_index = calculate_whs_average(differentials)
    end

    # Round to one decimal place
    handicap_index.round(1)
  end

  private

  def calculate_whs_average(differentials)
    sorted = differentials.sort
    case differentials.length
    when 3..6
      sorted.first # Best 1
    when 7..8
      sorted.first(2).sum / 2.0 # Best 2
    when 9..11
      sorted.first(3).sum / 3.0 # Best 3
    else
      sorted.first(8).sum / 8.0 # Best 8 (for 20 rounds)
    end
  end
end
```

---

## Claude API Integration

### API Configuration
```ruby
# config/initializers/claude.rb
CLAUDE_API_KEY = ENV['CLAUDE_API_KEY']
CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'
CLAUDE_MODEL = 'claude-3-5-sonnet-20241022' # or latest model
```

### Prompt Structure for Training Plans

#### System Message
```
You are a professional golf coach and educator with deep knowledge of:
- Golf training methodologies
- Handicap improvement strategies
- Evidence-based practice techniques
- Time management for golf training
- Physical conditioning for golf
- Mental game development

Provide educational, research-backed training recommendations.
```

#### User Prompt Template (Standard)
```
Create a comprehensive golf training plan with the following parameters:

Current Handicap: {current_handicap}
Target Handicap: {target_handicap}
Timeline: {timeline_months} months
Improvement Needed: {handicap_difference} strokes

Generate THREE training guides:

1. SIMPLE GUIDE (Beginner-friendly, 300-400 words)
   - High-level overview
   - Weekly time commitment
   - Top 3-5 focus areas
   - Basic drills and exercises

2. MEDIUM GUIDE (Moderate detail, 600-800 words)
   - Weekly/monthly breakdown
   - Specific practice drills
   - Skill development priorities
   - Progress milestones
   - Equipment recommendations

3. COMPLEX GUIDE (Comprehensive, 1000-1500 words)
   - Detailed daily/weekly schedule
   - Advanced technique work
   - Physical conditioning program
   - Mental game strategies
   - Video analysis recommendations
   - Practice vs. play ratio
   - Progress tracking methods
   - Common pitfalls to avoid

Base all recommendations on professional golf research and proven coaching methods.
Include realistic expectations about improvement rates.
```

#### Additional Prompt for Predicted Handicap (NEW)
```
Analyze these golf scores and provide context for the predicted handicap:

Round 1: {score_1} at {course_1} (Rating: {rating_1}, Slope: {slope_1})
Round 2: {score_2} at {course_2} (Rating: {rating_2}, Slope: {slope_2})
Round 3: {score_3} at {course_3} (Rating: {rating_3}, Slope: {slope_3})

Predicted Handicap Index: {predicted_handicap}

Provide:
1. Validation of the calculation
2. What this handicap typically means in terms of skill level
3. Key areas that likely need improvement based on the scores
4. Encouraging context for the golfer

Keep response to 150-200 words.
```

---

## Features & Functionality

### Phase 1: MVP (Minimum Viable Product)
- [ ] User authentication (sign up, login, logout)
- [ ] **User Path Selection**: Choose between official handicap or score upload
- [ ] Simple form to input handicap data and timeline (Use Case 1)
- [ ] **Multi-step form for 3 rounds of golf scores** (Use Case 2 - NEW)
- [ ] **Handicap calculation service** (Use Case 2 - NEW)
- [ ] **Display predicted handicap with explanation** (Use Case 2 - NEW)
- [ ] Claude API integration for plan generation
- [ ] Display all three guide levels on results page
- [ ] Save training plans to database
- [ ] View previous training plans

### Phase 2: Enhanced Features
- [ ] User dashboard with training plan history
- [ ] Progress tracking (users can log their practice sessions)
- [ ] Update handicap over time
- [ ] **Store and track multiple handicap calculations**
- [ ] **Upload more than 3 rounds for better accuracy**
- [ ] Print/PDF export of training plans
- [ ] Email delivery of training plans

### Phase 3: Advanced Features
- [ ] Community features (share progress, success stories)
- [ ] Integration with golf stat tracking APIs
- [ ] **Golf course database with automatic rating/slope lookup**
- [ ] **Score card image upload with OCR parsing**
- [ ] Video upload/analysis integration
- [ ] Reminder system for training sessions
- [ ] Mobile-responsive design improvements

---

## Database Schema

```ruby
# db/schema.rb

create_table "users", force: :cascade do |t|
  t.string "email", null: false
  t.string "encrypted_password", null: false
  t.boolean "has_official_handicap", default: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["email"], name: "index_users_on_email", unique: true
end

create_table "golf_rounds", force: :cascade do |t|
  t.bigint "user_id"
  t.string "course_name", null: false
  t.integer "score", null: false
  t.decimal "course_rating", precision: 4, scale: 1, null: false
  t.integer "slope_rating", null: false
  t.date "played_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["user_id"], name: "index_golf_rounds_on_user_id"
end

create_table "handicap_calculations", force: :cascade do |t|
  t.bigint "user_id"
  t.decimal "calculated_handicap", precision: 4, scale: 1, null: false
  t.string "calculation_method", default: "predicted"
  t.text "ai_context"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["user_id"], name: "index_handicap_calculations_on_user_id"
end

create_table "handicap_calculation_rounds", force: :cascade do |t|
  t.bigint "handicap_calculation_id", null: false
  t.bigint "golf_round_id", null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["handicap_calculation_id"], name: "index_hc_rounds_on_calculation"
  t.index ["golf_round_id"], name: "index_hc_rounds_on_round"
end

create_table "training_plans", force: :cascade do |t|
  t.bigint "user_id"
  t.bigint "handicap_calculation_id"
  t.decimal "current_handicap", precision: 4, scale: 1
  t.decimal "target_handicap", precision: 4, scale: 1
  t.integer "timeline_months"
  t.text "simple_guide"
  t.text "medium_guide"
  t.text "complex_guide"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["user_id"], name: "index_training_plans_on_user_id"
  t.index ["handicap_calculation_id"], name: "index_training_plans_on_handicap_calc"
end

add_foreign_key "golf_rounds", "users"
add_foreign_key "handicap_calculations", "users"
add_foreign_key "handicap_calculation_rounds", "handicap_calculations"
add_foreign_key "handicap_calculation_rounds", "golf_rounds"
add_foreign_key "training_plans", "users"
add_foreign_key "training_plans", "handicap_calculations"
```

---

## User Interface Flow

### Landing Page
```
[Welcome to Golf Coach]

How would you like to get started?

[ I have an official handicap ] → Use Case 1 Flow
[ I don't have a handicap yet ] → Use Case 2 Flow
```

### Use Case 2: Score Upload Flow

**Step 1: Introduction**
```
Let's calculate your handicap!

Please enter your scores from your last 3 rounds of golf.
We'll use this to estimate your current handicap.

[Continue]
```

**Step 2: Round 1 Input**
```
Round 1 of 3

Course Name: [__________]
Your Score: [___]
Course Rating: [___._] (found on scorecard)
Slope Rating: [___] (found on scorecard)
Date Played: [MM/DD/YYYY]

[? What are Course Rating and Slope?]
[Continue]
```

**Step 3-4: Rounds 2 & 3** (same as above)

**Step 5: Handicap Result**
```
Your Predicted Handicap: 18.5

Based on your three rounds, your estimated handicap index is 18.5.

[AI-Generated Context from Claude explaining what this means]

Ready to create your training plan?
[Continue to Training Plan]
```

**Step 6: Training Plan Input**
```
What's your target handicap? [___]
Timeline to achieve your goal: [___ months]

[Generate Training Plan]
```

---

## Environment Setup

### Required Environment Variables
```bash
# .env
CLAUDE_API_KEY=your_anthropic_api_key_here
DATABASE_URL=your_database_url
SECRET_KEY_BASE=your_rails_secret_key
```

### Dependencies (Gemfile)
```ruby
gem 'rails', '~> 7.1'
gem 'pg' # or 'sqlite3' for development
gem 'bcrypt', '~> 3.1.7' # For user authentication
gem 'httparty' # For API requests to Claude
gem 'dotenv-rails' # Environment variable management
gem 'turbo-rails' # Hotwire
gem 'stimulus-rails' # Hotwire
gem 'tailwindcss-rails' # Styling (optional)
gem 'wicked' # Multi-step forms (optional, helpful for score input)
```

---

## Development Roadmap

### Week 1-2: Setup & Authentication
- Initialize Rails app
- Set up database
- Implement user authentication (Devise or custom)
- Create basic layout and navigation

### Week 3-4: Core Functionality
- **Build path selection (official vs. predicted handicap)**
- **Implement GolfRound model and multi-step form**
- **Create HandicapCalculatorService**
- Build TrainingPlan model and controller
- Create input form for handicap/timeline data (Use Case 1)
- Implement ClaudeApiService
- Build plan generation logic
- Create results display page

### Week 5-6: Polish & Testing
- Add styling and responsive design
- Implement error handling
- Write tests (RSpec recommended)
- Add user dashboard
- **Test handicap calculation accuracy**
- Deploy to production (Heroku, Render, or Fly.io)

---

## Validation Rules

### Golf Round Input
```ruby
# app/models/golf_round.rb

validates :score, presence: true,
                  numericality: {
                    only_integer: true,
                    greater_than: 50,
                    less_than: 200
                  }

validates :course_rating, presence: true,
                          numericality: {
                            greater_than: 60.0,
                            less_than: 80.0
                          }

validates :slope_rating, presence: true,
                         numericality: {
                           only_integer: true,
                           greater_than: 55,
                           less_than: 155
                         }

validates :course_name, presence: true, length: { minimum: 3 }
```

### Handicap Calculation
```ruby
# Ensure at least 3 rounds for calculation
validates :golf_rounds, length: { minimum: 3 }

# Handicap result should be reasonable
validates :calculated_handicap, numericality: {
  greater_than_or_equal_to: 0.0,
  less_than_or_equal_to: 54.0
}
```

---

## API Rate Limiting & Cost Considerations

### Claude API Usage
- **Use Case 1**: 1 API call per training plan (~2000-3000 tokens)
- **Use Case 2**: 2 API calls (handicap context + training plan ~3500-4500 tokens total)
- Consider caching similar requests
- Implement rate limiting to control costs

### Optimization Strategies
- Cache common handicap combinations
- Make handicap context API call optional (can calculate without Claude)
- Implement request throttling (e.g., 1 plan per user per hour)
- Consider batch processing for multiple users

---

## Security Considerations

1. **API Key Protection**
   - Never commit API keys to version control
   - Use environment variables
   - Rotate keys regularly

2. **User Authentication**
   - Use bcrypt for password hashing
   - Implement session management
   - Add CSRF protection (Rails default)
   - **Allow guest users for Use Case 2** (store with session ID)

3. **Input Validation**
   - Validate handicap ranges (0-54 for men, 0-60 for women)
   - Validate score inputs (realistic golf scores)
   - Validate course rating and slope rating ranges
   - Ensure timeline is reasonable (1-36 months)
   - Sanitize all user inputs

4. **API Request Validation**
   - Verify user is authenticated (or guest session valid) before API calls
   - Log all API requests for monitoring
   - Handle API failures gracefully

---

## Testing Strategy

### Unit Tests
- Model validations (GolfRound, HandicapCalculation)
- **HandicapCalculatorService accuracy**
- Service class methods
- Helper functions

### Integration Tests
- User authentication flow
- **Multi-step score input flow**
- **Handicap calculation and display**
- Training plan creation flow
- API integration (with VCR for recording HTTP interactions)

### System Tests
- End-to-end user journey (both use cases)
- Form submissions
- Results display
- **Score upload with validation errors**

---

## Deployment

### Recommended Platforms
1. **Render** - Easy Rails deployment, free tier available
2. **Heroku** - Classic Rails hosting
3. **Fly.io** - Modern, cost-effective option

### Deployment Checklist
- [ ] Set environment variables in production
- [ ] Configure production database
- [ ] Set up SSL/HTTPS
- [ ] Configure email delivery (if needed)
- [ ] Set up monitoring (Sentry, Rollbar)
- [ ] Configure backups
- [ ] Add analytics (Google Analytics, Plausible)

---

## Future Enhancements

### Handicap-Related Features
- **Upload more than 3 rounds** for better accuracy (up to 20 rounds)
- **Golf course database integration** (auto-populate ratings)
- **Score card OCR** - take photo of scorecard
- **Track handicap over time** with charts
- **GHIN API integration** for official handicap lookup

### AI/ML Improvements
- Use Claude to analyze user progress and adjust plans
- Implement conversational interface for plan refinement
- Add Q&A feature for golf technique questions
- **Score pattern analysis** - identify weaknesses from round data

### Social Features
- Share success stories
- Community forum
- Coach marketplace (connect with real coaches)

### Data Integration
- Connect with golf scoring apps (Golfshot, 18Birdies)
- Import rounds data automatically
- Track improvement metrics visually

### Mobile App
- React Native or Flutter companion app
- Push notifications for training reminders
- Quick logging of practice sessions
- **Quick score input after rounds**

---

## Learning Resources for Ruby on Rails

### Recommended Tutorials
- **Official Rails Guides**: https://guides.rubyonrails.org/
- **The Odin Project**: Full-stack Ruby on Rails curriculum
- **GoRails**: Video tutorials for modern Rails development
- **Ruby Koans**: Learn Ruby fundamentals

### Books
- "Agile Web Development with Rails 7" by Sam Ruby
- "The Well-Grounded Rubyist" by David A. Black
- "Rails AntiPatterns" (once you're comfortable)

### Community
- Rails Forum: https://discuss.rubyonrails.org/
- Reddit: r/rails
- Discord: Ruby on Rails community

---

## Project Structure

```
golfcoachapp/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── users_controller.rb
│   │   ├── golf_rounds_controller.rb (NEW)
│   │   ├── handicap_calculations_controller.rb (NEW)
│   │   └── training_plans_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── golf_round.rb (NEW)
│   │   ├── handicap_calculation.rb (NEW)
│   │   └── training_plan.rb
│   ├── services/
│   │   ├── claude_api_service.rb
│   │   ├── handicap_calculator_service.rb (NEW)
│   │   └── training_plan_generator.rb
│   ├── views/
│   │   ├── layouts/
│   │   ├── sessions/
│   │   ├── users/
│   │   ├── golf_rounds/ (NEW)
│   │   ├── handicap_calculations/ (NEW)
│   │   └── training_plans/
│   └── helpers/
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── initializers/
│       └── claude.rb
├── db/
│   ├── migrate/
│   └── schema.rb
├── spec/ (or test/)
├── .env
├── Gemfile
└── README.md
```

---

## Success Metrics

### User Engagement
- Number of training plans created (both use cases)
- **Adoption rate of score upload feature**
- Return user rate
- Time spent on platform

### Technical Performance
- API response time < 5 seconds
- **Handicap calculation accuracy** (compare with official calculations)
- 99% uptime
- Error rate < 1%

### Educational Value
- User satisfaction surveys
- Success stories (handicap improvement)
- **Accuracy of predicted handicaps** (validate with users who later get official handicap)
- Community engagement

---

## Getting Started - Quick Commands

```bash
# Create new Rails app
rails new golfcoachapp --database=postgresql

# Generate models
rails generate model User email:string encrypted_password:string has_official_handicap:boolean
rails generate model GolfRound user:references course_name:string score:integer course_rating:decimal slope_rating:integer played_at:date
rails generate model HandicapCalculation user:references calculated_handicap:decimal calculation_method:string ai_context:text
rails generate model TrainingPlan user:references handicap_calculation:references current_handicap:decimal target_handicap:decimal timeline_months:integer simple_guide:text medium_guide:text complex_guide:text

# Run migrations
rails db:migrate

# Start server
rails server

# Run tests
rails test
# or with RSpec
rspec
```

---

## Sample Handicap Calculation Example

```
Round 1: Pine Valley CC
- Score: 92
- Course Rating: 71.5
- Slope: 135
- Differential: (113/135) × (92-71.5) = 17.1

Round 2: Pebble Beach
- Score: 88
- Course Rating: 72.8
- Slope: 145
- Differential: (113/145) × (88-72.8) = 11.9

Round 3: Augusta National
- Score: 95
- Course Rating: 74.0
- Slope: 140
- Differential: (113/140) × (95-74.0) = 16.9

With 3 rounds, use lowest differential minus 2:
Predicted Handicap = 11.9 - 2.0 = 9.9

(Note: This is a simplified calculation. Production should follow full WHS guidelines)
```

---

## Conclusion

This specification provides a complete roadmap for building your golf coach educational app with **two distinct user paths**: one for golfers with official handicaps and another for those who need their handicap predicted from recent scores.

The score upload feature makes your app accessible to casual golfers who don't have official handicaps yet, significantly expanding your potential user base. The handicap calculation service provides immediate value and builds trust before users even generate their training plan.

Start with the MVP features, test with real users (especially the handicap calculation accuracy), and iterate based on feedback. The combination of Ruby on Rails and Claude API will give you a powerful, scalable platform for delivering personalized golf training education.

Remember: Focus on providing genuine educational value. The goal is to help golfers understand what they need to practice and why, not just to tell them what to do.
