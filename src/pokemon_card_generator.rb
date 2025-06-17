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
    pointsize: "52",
    fill: "black",
    stroke: "black", 
    strokewidth: "0",
    position: "+99+80"
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
    pointsize: "42",
    fill: "black",
    position: "+160+850",
    max_chars_per_line: 25
  }.freeze

  def initialize(guest)
    @guest = guest
  end

  def generate_cards
    puts "\n🎴 Génération de la carte Pokemon pour #{@guest.get_username}..."
    
    ensure_output_directory
    
    temp_photo_path = download_user_photo
    return nil unless temp_photo_path
    
    begin
      base_card = create_base_card(temp_photo_path)
      return nil unless base_card
      
      generated_files = []
      
      @guest.questions.each do |question|
        next if question.nil? || question.strip.empty?
        
        output_path = generate_output_filename(question)
        create_card_with_convert(base_card, question, output_path)
        
        puts "🎉 Carte générée: #{File.basename(output_path)}"
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
    user_photos = @guest.photo
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

  def create_base_card(temp_photo_path)
    puts "🔧 Création de la carte de base..."
    
    base_card_path = "temp_base_#{@guest.get_username}.png"
    
    photo_info = get_photo_dimensions(temp_photo_path)
    cover_dimensions = calculate_cover_dimensions(photo_info)
    center_offsets = calculate_center_offsets(cover_dimensions)
    
    MiniMagick::Tool::Convert.new do |convert|
      # Load the template
      convert << template_path
      
      # Process and compose the photo exactly
      convert << "(" << temp_photo_path
      convert << "-resize" << "#{cover_dimensions[:width]}x#{cover_dimensions[:height]}!"
      convert << "-crop" << "#{FRAME_CONFIG[:width]}x#{FRAME_CONFIG[:height]}+#{center_offsets[:x]}+#{center_offsets[:y]}"
      convert << ")"
      convert << "-geometry" << "+#{FRAME_CONFIG[:x]}+#{FRAME_CONFIG[:y]}"
      convert << "-composite"
      
      # Add username
      username = "@#{@guest.get_username}"
      convert << "-font" << USERNAME_CONFIG[:font]
      convert << "-pointsize" << USERNAME_CONFIG[:pointsize]
      convert << "-fill" << USERNAME_CONFIG[:fill]
      convert << "-gravity" << "NorthWest"
      convert << "-annotate" << USERNAME_CONFIG[:position] << username
      
      # Add PV
      pv_value = generate_user_pv(@guest.get_username)
      convert << "-font" << PV_CONFIG[:font]
      convert << "-pointsize" << PV_CONFIG[:pointsize]
      convert << "-fill" << PV_CONFIG[:fill]
      convert << "-gravity" << "NorthEast"
      convert << "-annotate" << PV_CONFIG[:position] << pv_value.to_s
      
      convert << base_card_path
    end
    
    puts "✅ Carte de base créée"
    base_card_path
  end

  def create_card_with_convert(base_card_path, question, output_path)
    formatted_question = format_text_with_line_breaks(question, max_chars_per_line: QUESTION_CONFIG[:max_chars_per_line])
    
    MiniMagick::Tool::Convert.new do |convert|
      convert << base_card_path
      convert << "-font" << QUESTION_CONFIG[:font]
      convert << "-pointsize" << QUESTION_CONFIG[:pointsize]
      convert << "-fill" << QUESTION_CONFIG[:fill]
      convert << "-gravity" << "NorthWest"
      convert << "-annotate" << QUESTION_CONFIG[:position] << "Question: #{formatted_question}"
      convert << output_path
    end
  end

  def get_photo_dimensions(photo_path)
    image = MiniMagick::Image.open(photo_path)
    {
      width: image.width.to_f,
      height: image.height.to_f
    }
  end

  def calculate_cover_dimensions(photo_info)
    target_ratio = FRAME_CONFIG[:width].to_f / FRAME_CONFIG[:height].to_f
    original_ratio = photo_info[:width] / photo_info[:height]
    
    if original_ratio > target_ratio
      scale_factor = FRAME_CONFIG[:height] / photo_info[:height]
      {
        width: (photo_info[:width] * scale_factor).to_i,
        height: FRAME_CONFIG[:height]
      }
    else
      scale_factor = FRAME_CONFIG[:width] / photo_info[:width]
      {
        width: FRAME_CONFIG[:width],
        height: (photo_info[:height] * scale_factor).to_i
      }
    end
  end

  def calculate_center_offsets(new_dimensions)
    {
      x: (new_dimensions[:width] - FRAME_CONFIG[:width]) / 2,
      y: (new_dimensions[:height] - FRAME_CONFIG[:height]) / 2
    }
  end

  def generate_temp_filename
    "temp_photo_#{@guest.username}.jpg"
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

  def generate_output_filename(question)
    "output/pokemon_card_#{@guest.get_username}_#{question.gsub(" ", "_")}.png"
  end

  def cleanup_temp_file(temp_photo_path)
    File.delete(temp_photo_path) if temp_photo_path && File.exist?(temp_photo_path)
    
    # Nettoyer aussi la carte de base temporaire
    base_card_path = "temp_base_#{@guest.get_username}.png"
    File.delete(base_card_path) if File.exist?(base_card_path)
  end

  def handle_error(error)
    puts "❌ Erreur lors de la génération: #{error.message}"
    puts error.backtrace.first(3)
  end
  
  def template_path
    case @guest.gender
    when "Homme"
      "assets/card_template_male.png"
    when "Femme"
      "assets/card_template_female.png"
    else
      "assets/card_template_male.png"
    end
  end
end