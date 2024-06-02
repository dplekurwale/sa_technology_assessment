require 'pstore' # https://github.com/ruby/pstore

QUESTIONS = {
  "q1" => "Can you code in Ruby?",
  "q2" => "Can you code in JavaScript?",
  "q3" => "Can you code in Swift?",
  "q4" => "Can you code in Java?",
  "q5" => "Can you code in C#?"
}.freeze

class Question
  attr_accessor :statement, :options
  def initialize(id, statement, options)
    @id = id 
    @statement = statement 
    @options = options
  end

  def valid_input?(ans)
    @options.each do |option|
      if option.value == ans.downcase
        return true
      end
    end
    return false
  end

  def score(ans)
    @options.select{|answer| answer.value == ans.downcase}.first.score
  end

  def select_option
    @options.map{|k| k.value}.join(', ')
  end
end

class Answer
  attr_accessor :value, :score
  def initialize(value, score)
    @value = value
    @score = score
  end
end

class Survey
  STORE_NAME = "tendable.pstore"

  attr_accessor :questions
  attr_reader :score

  def initialize(questions)
    @questions = questions
    @score = 0
    @store = PStore.new(STORE_NAME)
  end

  def do_survey
    self.questions.each do |question|
      print(question.statement)
      ans = gets.chomp
      while !question.valid_input?(ans)
        print("please enter one of the options ---#{question.select_option}")
        ans = gets.chomp
      end
      @score += question.score(ans)
    end
    save_in_db
    puts "Rating for this run: #{(@score/question_count)}%"
    puts "Average rating for all runs: #{average_rating}%"
  end

  def save_in_db
    @store.transaction do
      @store[:scores] ||= []
      @store[:scores] << score
    end
  end

  def average_rating
    @store.transaction do
      scores = @store[:scores] || []
      return 0.0 if scores.empty?
      (@store[:scores].sum / (question_count * @store[:scores].count)).round(2)
    end
  end

  def question_count 
    self.questions.count
  end

  def clear_store
    @store.transaction do
      @store[:scores] = []
    end
  end
end

if __FILE__ == $0
  questions = QUESTIONS.map do |k, v|
    options = [Answer.new('y', 100), Answer.new('n', 0), Answer.new('yes', 100), Answer.new('no', 0)]
    Question.new(k, v, options)
  end

  # Survey.new(questions).clear_store
  Survey.new(questions).do_survey
end
