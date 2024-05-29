require 'pstore' # https://github.com/ruby/pstore

class Questionnaire
  STORE_NAME = "tendable.pstore"
  QUESTIONS = {
    "q1" => "Can you code in Ruby?",
    "q2" => "Can you code in JavaScript?",
    "q3" => "Can you code in Swift?",
    "q4" => "Can you code in Java?",
    "q5" => "Can you code in C#?"
  }.freeze
  VALID_ANSWERS = ['yes', 'y', 'no', 'n'].freeze
  YES_ANSWERS = ['yes', 'y'].freeze

  def initialize
    @store = PStore.new(STORE_NAME)
  end

  def do_prompt
    # Ask each question and get an answer from the user's input.
    total_yes_answers = 0
    total_questions = QUESTIONS.length
    answers = {}

    QUESTIONS.each do |question_key, question|
      print "#{question} "
      answer = gets.chomp.downcase
      while !valid_input?(answer)
        print("please enter one of the options ---#{VALID_ANSWERS}")
        answer = gets.chomp
      end
      answers[question_key] = answer
      total_yes_answers += 1 if YES_ANSWERS.include? answer
    end

    @store.transaction do
      @store[:answers] ||= []
      @store[:answers] << answers
    end

    rating = calculate_rating(total_yes_answers, total_questions)
    puts "Rating for this run: #{rating}%"
  end

  def do_report
    average_rating = calculate_average_rating
    puts "Average rating for all runs: #{average_rating}%"
  end

  private

  def calculate_rating(yes_answers, total_questions)
    (yes_answers.to_f / total_questions * 100).round(2)
  end

  def calculate_average_rating
    total_ratings = 0
    total_runs = 0

    @store.transaction do
      return 0 if @store[:answers].nil?

      @store[:answers].each do |answers|
        total_yes_answers = answers.count { |_key, value| YES_ANSWERS.include? value }
        total_questions = answers.length
        total_runs += 1
        total_ratings += calculate_rating(total_yes_answers, total_questions)
      end
    end

    (total_ratings / total_runs).round(2)
  end

  def valid_input?(ans)
    VALID_ANSWERS.each do |answer|
      if answer == ans.downcase
        return true
      end
    end
    return false
  end

  def clear_store_answers
    @store.transaction do
      @store[:answers] = []
    end
  end
end
