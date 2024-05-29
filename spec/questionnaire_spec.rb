require 'rspec'
require 'pstore'
require_relative '../questionnaire'

RSpec.describe Questionnaire do
  let(:store_name) { 'test_store.pstore' }
  let(:survey) { Questionnaire.new }

  before(:each) do
    @store = PStore.new(store_name)
    allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes') # Default stub to prevent hangs
    survey.instance_variable_set(:@store, @store)
  end

  after(:each) do
    File.delete(store_name) if File.exist?(store_name)
  end

  describe '#valid_input?' do
    it 'returns true for valid inputs' do
      %w[yes y no n].each do |answer|
        expect(survey.send(:valid_input?, answer)).to be true
      end
    end

    it 'returns false for invalid inputs' do
      expect(survey.send(:valid_input?, 'invalid')).to be false
    end
  end

  describe '#do_prompt' do
    it 'prompts the user for each question and stores answers' do
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes', 'no', 'yes', 'no', 'no')
      expect { survey.do_prompt }.to output(/Can you code in Ruby?.*Can you code in JavaScript?.*Can you code in Swift?.*Can you code in Java?.*Can you code in C#?/m).to_stdout

      stored_answers = nil
      @store.transaction { stored_answers = @store[:answers] }

      expect(stored_answers).not_to be_nil
      expect(stored_answers.last).to eq({ 'q1' => 'yes', 'q2' => 'no', 'q3' => 'yes', 'q4' => 'no', 'q5' => 'no' })
    end

    it 'calculates and prints the rating for the current run' do
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes', 'yes', 'no', 'yes', 'no')
      expect { survey.do_prompt }.to output(/Rating for this run: 60.0%/).to_stdout
    end
  end

  describe '#calculate_rating' do
    it 'returns the correct rating' do
      expect(survey.send(:calculate_rating, 3, 5)).to eq(60.0)
    end
  end

  describe '#calculate_average_rating' do
    it 'returns the correct average rating' do
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes', 'no', 'no', 'yes', 'no')
      survey.do_prompt

      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('no', 'no', 'no', 'no', 'no')
      survey.do_prompt

      expect(survey.send(:calculate_average_rating)).to eq(20.0)
    end
  end

  describe '#do_report' do
    it 'calculates and prints the average rating for all runs' do
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes', 'yes', 'yes', 'yes', 'no')
      survey.do_prompt
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('no', 'no', 'no', 'no', 'no')
      survey.do_prompt
      expect { survey.do_report }.to output(/Average rating for all runs: 40.0%/).to_stdout
    end
  end

  describe '#clear_store_answers' do
    it 'clears all stored answers' do
      allow_any_instance_of(Questionnaire).to receive(:gets).and_return('yes', 'yes', 'no', 'yes', 'no')
      survey.do_prompt
      survey.send(:clear_store_answers)
      stored_answers = nil
      @store.transaction { stored_answers = @store[:answers] }
      expect(stored_answers).to eq([])
    end
  end
end
