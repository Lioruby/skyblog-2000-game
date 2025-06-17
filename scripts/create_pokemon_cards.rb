require 'airtable'
require 'dotenv'
require 'awesome_print'
require 'active_support/core_ext/hash'
require_relative 'src/pokemon_card_generator'
require_relative 'src/guest'

Dotenv.load

AIRTABLE_API_KEY = ENV['AIRTABLE_API_KEY']
AIRTABLE_APP_ID = ENV['AIRTABLE_APP_ID']
AIRTABLE_TABLE_ID = ENV['AIRTABLE_TABLE_ID']


def create_pokemon_cards
  client = Airtable::Client.new(AIRTABLE_API_KEY)
  table = client.table(AIRTABLE_APP_ID, AIRTABLE_TABLE_ID)

  records = table.all

  records.each_with_index do |record, index|
    ap "Processing record #{index + 1} of #{records.length}"
    guest = Guest.new(
      record[:instagram],
      record[:photo],
      [
        record[:question],
        record[:question_2],
        record[:question_3],
        record[:question_4],
        record[:question_5]
      ].compact,
      record[:genre]
    )
    
    pokemon_card_generator = PokemonCard.new(guest)
    pokemon_card_generator.generate_cards
  end
end

create_pokemon_cards