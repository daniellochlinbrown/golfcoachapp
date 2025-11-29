# Service for interacting with the Anthropic Claude API
class ClaudeApiService
  include HTTParty
  base_uri "https://api.anthropic.com"

  def initialize
    @api_key = ENV["CLAUDE_API_KEY"]
    @model = "claude-sonnet-4-20250514"
  end

  # Generate training plan from handicap information
  def generate_training_plan(current_handicap, target_handicap, timeline_months)
    handicap_difference = current_handicap - target_handicap

    prompt = build_training_plan_prompt(
      current_handicap,
      target_handicap,
      timeline_months,
      handicap_difference
    )

    response = make_api_call(prompt)
    parse_training_plan_response(response)
  end

  # Generate context for predicted handicap
  def generate_handicap_context(golf_rounds, predicted_handicap)
    prompt = build_handicap_context_prompt(golf_rounds, predicted_handicap)
    response = make_api_call(prompt)
    response["content"].first["text"] if response.dig("content", 0, "text")
  end

  private

  def make_api_call(user_message)
    headers = {
      "x-api-key" => @api_key,
      "anthropic-version" => "2023-06-01",
      "Content-Type" => "application/json"
    }

    body = {
      model: @model,
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: user_message
        }
      ],
      system: system_message
    }

    response = self.class.post(
      "/v1/messages",
      headers: headers,
      body: body.to_json,
      timeout: 120  # 120 second timeout
    )

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error("Claude API Error: #{response.code} - #{response.body}")
      raise "API call failed: #{response.code} - #{response.body}"
    end
  rescue Net::ReadTimeout => e
    Rails.logger.error("Claude API Timeout: #{e.message}")
    raise "Request timed out. Please try again."
  rescue => e
    Rails.logger.error("Claude API Error: #{e.class} - #{e.message}")
    raise "API error: #{e.message}"
  end

  def system_message
    <<~SYSTEM
      You are a professional golf coach and educator with deep knowledge of:
      - Golf training methodologies
      - Handicap improvement strategies
      - Evidence-based practice techniques
      - Time management for golf training
      - Physical conditioning for golf
      - Mental game development

      Provide educational, research-backed training recommendations that help golfers understand
      what they need to practice and why, not just what to do.
    SYSTEM
  end

  def build_training_plan_prompt(current, target, timeline, difference)
    <<~PROMPT
      Create a comprehensive golf training plan with the following parameters:

      Current Handicap: #{current}
      Target Handicap: #{target}
      Timeline: #{timeline} months
      Improvement Needed: #{difference.round(1)} strokes

      Generate THREE training guides. Format your response EXACTLY as follows, with clear section markers:

      === QUICK START GUIDE ===
      [Your quick start guide content here - 300-400 words]
      - High-level overview
      - Weekly time commitment
      - Top 3-5 focus areas
      - Essential drills and exercises
      - Quick wins

      === COMPLETE PLAN ===
      [Your complete plan content here - 600-800 words]
      - Weekly/monthly breakdown
      - Specific practice drills and techniques
      - Skill development priorities
      - Progress milestones
      - Equipment recommendations
      - Practice routines

      === ADVANCED PLAN ===
      [Your advanced plan content here - 1000-1500 words]
      - Detailed daily/weekly schedule
      - Advanced technique work
      - Physical conditioning program
      - Mental game strategies
      - Video analysis recommendations
      - Practice vs. play ratio
      - Progress tracking methods
      - Common pitfalls to avoid
      - Performance optimization

      Base all recommendations on professional golf research and proven coaching methods.
      Include realistic expectations about improvement rates.
      Make the content educational and explain the "why" behind recommendations.
    PROMPT
  end

  def build_handicap_context_prompt(golf_rounds, predicted_handicap)
    rounds_info = golf_rounds.map.with_index do |round, i|
      "Round #{i + 1}: #{round.score} at #{round.course_name} (Rating: #{round.course_rating}, Slope: #{round.slope_rating})"
    end.join("\n")

    <<~PROMPT
      Analyze these golf scores and provide context for the predicted handicap:

      #{rounds_info}

      Predicted Handicap Index: #{predicted_handicap}

      Provide:
      1. Validation of the calculation
      2. What this handicap typically means in terms of skill level
      3. Key areas that likely need improvement based on the scores
      4. Encouraging context for the golfer

      Keep response to 150-200 words. Be encouraging and educational.
    PROMPT
  end

  def parse_training_plan_response(response)
    content = response.dig("content", 0, "text")
    return { simple: "", medium: "", complex: "" } unless content

    # Extract each guide based on section markers
    simple_guide = extract_section(content, "QUICK START GUIDE", "COMPLETE PLAN")
    medium_guide = extract_section(content, "COMPLETE PLAN", "ADVANCED PLAN")
    complex_guide = extract_section(content, "ADVANCED PLAN", nil)

    {
      simple: simple_guide.strip,
      medium: medium_guide.strip,
      complex: complex_guide.strip
    }
  end

  def extract_section(content, start_marker, end_marker)
    start_pattern = /===\s*#{Regexp.escape(start_marker)}\s*===/i
    start_match = content.match(start_pattern)
    return "" unless start_match

    start_pos = start_match.end(0)

    if end_marker
      end_pattern = /===\s*#{Regexp.escape(end_marker)}\s*===/i
      end_match = content.match(end_pattern)
      end_pos = end_match ? end_match.begin(0) : content.length
    else
      end_pos = content.length
    end

    content[start_pos...end_pos]
  end
end
