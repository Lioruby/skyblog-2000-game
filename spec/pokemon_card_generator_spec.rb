require 'spec_helper'
require_relative '../src/generator'

RSpec.describe PokemonCardGenerator do
  describe '#initialize' do
    it 'creates a new instance' do
      generator = PokemonCardGenerator.new
      expect(generator).to be_a(PokemonCardGenerator)
    end
  end
end 