require 'airtable'
require 'dotenv'
require 'awesome_print'
require 'active_support/core_ext/hash'
require_relative 'src/pokemon_card_generator'

Dotenv.load

AIRTABLE_API_KEY = ENV['AIRTABLE_API_KEY']
AIRTABLE_APP_ID = ENV['AIRTABLE_APP_ID']
AIRTABLE_TABLE_ID = ENV['AIRTABLE_TABLE_ID']

client = Airtable::Client.new(AIRTABLE_API_KEY)
table = client.table(AIRTABLE_APP_ID, AIRTABLE_TABLE_ID)

records = table.all

records.each_with_index do |record, index|
  ap "Processing record #{index + 1} of #{records.length}"
  pokemon_card_generator = PokemonCard.new(record)
  pokemon_card_generator.generate_cards
end
