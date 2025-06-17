require 'mini_magick'
require 'open-uri'
require 'fileutils'

class PokemonCard
  FRAME_CONFIG = {
    width: 740,
    height: 540,
    x: 115,
    y: 167
  }.freeze
  
  USERNAME_CONFIG = {
    font: "Arial-Bold",
    pointsize: "32",
    fill: "black",
    stroke: "black",
    strokewidth: "0",
    position: "+99+99"
  }.freeze

  PV_CONFIG = {
    font: "Arial-Bold",
    pointsize: "52",
    fill: "black",
    stroke: "black",
    strokewidth: "0",
    position: "+250+80"
  }.freeze

  QUESTION_CONFIG = {
    font: "Arial-Bold",
    pointsize: "34",
    fill: "black",
    position: "+25+260",
    max_chars_per_line: 30
  }.freeze

  def initialize(record)
    @record = record
  end

  def generate_cards
    puts "\n🎴 Génération de la carte Pokemon pour #{@record[:instagram]}..."
    
    ensure_output_directory
    
    temp_photo_path = download_user_photo
    return nil unless temp_photo_path
    
    begin
      user_photo = process_user_photo(temp_photo_path)


      questions = [
        @record[:question],
        @record[:question_2],
        @record[:question_3],
        @record[:question_4],
        @record[:question_5]
      ].compact

      card = load_template
      add_pv_to_card(card, @record[:instagram])
      add_username_to_card(card)
      
      generated_files = []
      
      questions.each do |question|
        next if question.nil? || question.strip.empty?
        
        final_card = compose_card(card, user_photo)
        add_question_to_card(final_card, question)
        output_path = save_card(final_card, question)
        puts "🎉 Carte générée avec succès: #{output_path}"
        
        generated_files << output_path
      end
      
      puts "✅ Total: #{generated_files.length} cartes générées"
      return generated_files
    
    rescue => e
      handle_error(e)
      return nil
    ensure
      cleanup_temp_file(temp_photo_path)
    end
  end

  private

  def ensure_output_directory
    FileUtils.mkdir_p('output')
  end

  def download_user_photo
    user_photos = @record[:photo]
    if user_photos.nil? || user_photos.empty?
      puts "❌ Aucune photo trouvée pour cet utilisateur"
      return nil
    end
    
    photo_url = user_photos.first['url']
    puts "📸 URL de la photo: #{photo_url}"
    
    temp_photo_path = generate_temp_filename
    
    File.open(temp_photo_path, 'wb') do |file|
      URI.open(photo_url) { |data| file.write(data.read) }
    end
    
    puts "✅ Photo téléchargée temporairement"
    temp_photo_path
  end

  def generate_temp_filename
    "temp_photo_#{@record[:instagram]}.jpg"
  end

  def load_template
    card = MiniMagick::Image.open(template_path)
    puts "✅ Template chargé: #{card.width}x#{card.height}"
    card
  end

  def process_user_photo(temp_photo_path)
    user_photo = MiniMagick::Image.open(temp_photo_path)
    puts "📐 Photo originale: #{user_photo.width}x#{user_photo.height}"
    
    resize_photo_to_cover(user_photo)
    user_photo
  end

  def resize_photo_to_cover(user_photo)
    original_width = user_photo.width.to_f
    original_height = user_photo.height.to_f
    
    new_dimensions = calculate_cover_dimensions(original_width, original_height)
    
    user_photo.resize "#{new_dimensions[:width]}x#{new_dimensions[:height]}!"
    
    offsets = calculate_center_offsets(new_dimensions)
    
    user_photo.crop "#{FRAME_CONFIG[:width]}x#{FRAME_CONFIG[:height]}+#{offsets[:x]}+#{offsets[:y]}"
    
    puts "✅ Photo redimensionnée en mode cover: #{user_photo.width}x#{user_photo.height}"
  end

  def calculate_cover_dimensions(original_width, original_height)
    target_ratio = FRAME_CONFIG[:width].to_f / FRAME_CONFIG[:height].to_f
    original_ratio = original_width / original_height
    
    if original_ratio > target_ratio
      scale_factor = FRAME_CONFIG[:height] / original_height
      {
        width: (original_width * scale_factor).to_i,
        height: FRAME_CONFIG[:height]
      }
    else
      scale_factor = FRAME_CONFIG[:width] / original_width
      {
        width: FRAME_CONFIG[:width],
        height: (original_height * scale_factor).to_i
      }
    end
  end

  def calculate_center_offsets(new_dimensions)
    {
      x: (new_dimensions[:width] - FRAME_CONFIG[:width]) / 2,
      y: (new_dimensions[:height] - FRAME_CONFIG[:height]) / 2
    }
  end

  def compose_card(card, user_photo)
    composed_card = card.composite(user_photo) do |c|
      c.compose "Over"
      c.geometry "+#{FRAME_CONFIG[:x]}+#{FRAME_CONFIG[:y]}"
    end
    
    puts "✅ Photo intégrée au template"
    composed_card
  end

  def add_username_to_card(card)
    username = "@#{@record[:instagram].downcase.gsub("@", "")}"
    
    card.combine_options do |c|
      c.font USERNAME_CONFIG[:font]
      c.pointsize USERNAME_CONFIG[:pointsize]
      c.fill USERNAME_CONFIG[:fill]
      c.stroke USERNAME_CONFIG[:stroke]
      c.strokewidth USERNAME_CONFIG[:strokewidth]
      c.gravity "NorthWest"
      c.annotate USERNAME_CONFIG[:position], username
    end
    
    puts "✅ Nom d'utilisateur ajouté: #{username}"
    card
  end

  def add_question_to_card(card, question)
    formatted_question = format_text_with_line_breaks(question, max_chars_per_line: QUESTION_CONFIG[:max_chars_per_line])
    
    card.combine_options do |c|
      c.font QUESTION_CONFIG[:font]
      c.pointsize QUESTION_CONFIG[:pointsize]
      c.fill QUESTION_CONFIG[:fill]
      c.gravity "Center"
      c.annotate QUESTION_CONFIG[:position], "Question: #{formatted_question}"
    end
  end

  def format_text_with_line_breaks(text, max_chars_per_line:)
    return "" if text.nil? || text.empty?
    
    words = text.split(' ')
    lines = []
    current_line = ""
    
    words.each do |word|
      if (current_line + " " + word).length > max_chars_per_line && !current_line.empty?
        lines << current_line.strip
        current_line = word
      else
        current_line += current_line.empty? ? word : " " + word
      end
    end
    
    lines << current_line.strip unless current_line.empty?
    
    lines = lines.first(3)
    
    lines.join("\n")
  end

  def add_pv_to_card(card, username = nil)
    pv_value = generate_user_pv(username)
    card.combine_options do |c|
      c.font PV_CONFIG[:font]
      c.pointsize PV_CONFIG[:pointsize]
      c.fill PV_CONFIG[:fill]
      c.stroke PV_CONFIG[:stroke]
      c.strokewidth PV_CONFIG[:strokewidth]
      c.gravity "NorthEast"
      c.annotate PV_CONFIG[:position], pv_value
    end
  end

  def generate_user_pv(username = nil)
    return 500 if ["lioruby_", "vintagetran", "theoaudace", "haimlivai"].include?(username)

    min_value = 10
    max_value = 340
    step = 10
    
    number_of_options = ((max_value - min_value) / step) + 1
    
    random_index = rand(number_of_options)
    pv_value = min_value + (random_index * step)
    
    pv_value
  end

  def save_card(card, question)
    output_path = generate_output_filename(question)
    card.write(output_path)
    output_path
  end

  def generate_output_filename(question)
    "output/pokemon_card_#{@record[:instagram]}_#{question.gsub(" ", "_")}.png"
  end

  def cleanup_temp_file(temp_photo_path)
    File.delete(temp_photo_path) if temp_photo_path && File.exist?(temp_photo_path)
  end

  def handle_error(error)
    puts "❌ Erreur lors de la génération: #{error.message}"
    puts error.backtrace.first(3)
  end
  
  def template_path
    case @record[:genre]
    when "Homme"
      "assets/card_template_male.png"
    when "Femme"
      "assets/card_template_female.png"
    else
      "assets/card_template_male.png"
    end
  end
end