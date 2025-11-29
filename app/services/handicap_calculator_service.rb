# Service for calculating golf handicap index from golf rounds
# Implements World Handicap System (WHS) methodology
class HandicapCalculatorService
  def initialize(golf_rounds)
    @golf_rounds = golf_rounds
  end

  def calculate
    return 0.0 if @golf_rounds.empty?

    # Step 1: Calculate Score Differential for each round
    # Score Differential = (113 / Slope Rating) × (Adjusted Gross Score − Course Rating)
    differentials = @golf_rounds.map(&:score_differential)

    # Step 2: Determine handicap index based on number of rounds
    handicap_index = calculate_handicap_from_differentials(differentials)

    # Round to one decimal place
    handicap_index.round(1)
  end

  private

  def calculate_handicap_from_differentials(differentials)
    case differentials.length
    when 1..2
      # Not enough rounds for accurate calculation
      differentials.min - 2.0 # Rough estimate with adjustment
    when 3
      # For exactly 3 rounds, use lowest differential with adjustment
      differentials.min - 2.0
    when 4
      # Use lowest 1 differential with smaller adjustment
      differentials.min - 1.0
    when 5
      # Average of best 1 differential
      differentials.min
    when 6
      # Average of best 2 differentials
      differentials.sort.first(2).sum / 2.0
    when 7..8
      # Average of best 2 differentials
      differentials.sort.first(2).sum / 2.0
    when 9..11
      # Average of best 3 differentials
      differentials.sort.first(3).sum / 3.0
    when 12..14
      # Average of best 4 differentials
      differentials.sort.first(4).sum / 4.0
    when 15..16
      # Average of best 5 differentials
      differentials.sort.first(5).sum / 5.0
    when 17..18
      # Average of best 6 differentials
      differentials.sort.first(6).sum / 6.0
    when 19
      # Average of best 7 differentials
      differentials.sort.first(7).sum / 7.0
    else
      # 20+ rounds: Average of best 8 differentials (standard WHS)
      differentials.sort.first(8).sum / 8.0
    end
  end
end
