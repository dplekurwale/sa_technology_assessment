require 'rspec'
require 'pstore'
require 'byebug'
require_relative '../questionnaire' # Adjust path as necessary

RSpec.describe Answer do
  it 'initializes with a value and score' do
    answer = Answer.new('y', 100)
    expect(answer.value).to eq('y')
    expect(answer.score).to eq(100)
  end
end

RSpec.describe Question do
  let(:options) { [Answer.new('y', 100), Answer.new('n', 0), Answer.new('yes', 100), Answer.new('no', 0)] }
  let(:question) { Question.new('q1', 'Can you code in Ruby?', options) }

  it 'initializes with an id, statement, and options' do
    expect(question.instance_variable_get(:@id)).to eq('q1')
    expect(question.statement).to eq('Can you code in Ruby?')
    expect(question.options.length).to eq(4)
  end

  it 'validates input correctly' do
    expect(question.valid_input?('y')).to be true
    expect(question.valid_input?('yes')).to be true
    expect(question.valid_input?('maybe')).to be false
  end

  it 'returns the correct score based on the answer' do
    expect(question.score('y')).to eq(100)
    expect(question.score('n')). to eq(0)
  end
end

RSpec.describe Survey do
  let(:store_name) { 'test_store.pstore' }
  let(:questions) do
    QUESTIONS.map do |k, v|
      options = [Answer.new('y', 100), Answer.new('n', 0), Answer.new('yes', 100), Answer.new('no', 0)]
      Question.new(k, v, options)
    end
  end
  let(:survey) { Survey.new(questions) }

  before(:each) do
    @store = PStore.new(store_name)
    survey.instance_variable_set(:@store, @store)
    survey.clear_store # Clear store to ensure clean state for tests
  end

  it 'initializes with questions and score' do
    expect(survey.score).to eq(0)
    expect(survey.questions).to eq(questions)
  end

  it 'returns the correct question count' do
    expect(survey.question_count).to eq(5)
  end

  it 'returns an average rating of 0 with no runs' do
    expect(survey.average_rating).to eq(0.0)
  end

  it 'saves score in the database' do
    survey.instance_variable_set(:@score, 400) # Set a dummy score
    survey.save_in_db

    scores = []
    survey.instance_variable_get(:@store).transaction do
      scores = survey.instance_variable_get(:@store)[:scores]
    end
    expect(scores).to eq([400])
  end

  it 'returns the correct average rating' do
    survey.instance_variable_set(:@score, 400) # Set a dummy score
    survey.save_in_db
    expect(survey.average_rating).to eq(80.0)
  end

  it 'clears the store' do
    survey.instance_variable_set(:@score, 400) # Set a dummy score
    survey.save_in_db
    survey.clear_store

    scores = []
    survey.instance_variable_get(:@store).transaction do
      scores = survey.instance_variable_get(:@store)[:scores]
    end
    expect(scores).to eq([])
  end

  it 'completes the survey' do
    # Mock user input for each question
    allow(survey).to receive(:gets).and_return('y', 'n', 'yes', 'no', 'y')

    # Expect the survey to run without errors and check the output
    expect { survey.do_survey }.to output(/Rating for this run:/).to_stdout
    expect(survey.score).to eq(300)
  end
end
