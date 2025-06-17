require 'mini_magick'
require 'fileutils'

# Configuration des cartes
CARD_WIDTH_CM = 6.3
CARD_HEIGHT_CM = 8.8

# Conversion cm vers pixels (300 DPI)
DPI = 300
CARD_WIDTH_PX = (CARD_WIDTH_CM * DPI / 2.54).to_i  # 744px
CARD_HEIGHT_PX = (CARD_HEIGHT_CM * DPI / 2.54).to_i # 1039px

# Format A4 en pixels (300 DPI)
A4_WIDTH_PX = (21.0 * DPI / 2.54).to_i   # 2480px
A4_HEIGHT_PX = (29.7 * DPI / 2.54).to_i  # 3508px

# Calcul des marges et positions
MARGIN_PX = 60  # Marge pour la découpe
CARDS_PER_ROW = 3
CARDS_PER_COL = 3
CARDS_PER_PAGE = CARDS_PER_ROW * CARDS_PER_COL

# Espacement entre les cartes
SPACE_X = (A4_WIDTH_PX - 2 * MARGIN_PX - CARDS_PER_ROW * CARD_WIDTH_PX) / (CARDS_PER_ROW - 1)
SPACE_Y = (A4_HEIGHT_PX - 2 * MARGIN_PX - CARDS_PER_COL * CARD_HEIGHT_PX) / (CARDS_PER_COL - 1)

def create_printing_serie
  puts "🎴 Génération des PDFs d'impression en série..."
  
  card_files = Dir.glob("output/pokemon_card_*.png").sort
  
  puts "📊 #{card_files.length} cartes trouvées"
  puts "📐 Format: #{CARD_WIDTH_CM}cm x #{CARD_HEIGHT_CM}cm"
  puts "📄 #{CARDS_PER_PAGE} cartes par page A4"
  
  FileUtils.mkdir_p('printing_output')
  
  card_groups = card_files.each_slice(CARDS_PER_PAGE).to_a
  
  puts "📚 #{card_groups.length} pages à générer"
  
  card_groups.each_with_index do |cards_batch, page_index|
    puts "\n🎨 Page #{page_index + 1}/#{card_groups.length} (#{cards_batch.length} cartes)..."
    
    recto_filename = "printing_output/page_#{page_index + 1}_recto.pdf"
    create_page_with_convert(cards_batch, recto_filename)
    
    puts "✅ Page #{page_index + 1} générée"
  end
  
  puts "\n🎉 Génération terminée!"
  puts "📂 Fichiers dans: printing_output/"
  puts "📋 Instructions d'impression:"
  puts "   1. Imprimez d'abord tous les rectos"
  puts "   2. Retournez le papier"
  puts "   3. Imprimez les versos correspondants"
  puts "   4. Découpez en suivant les marges"
end

def create_page_with_convert(cards_batch, output_filename)
  MiniMagick::Tool::Convert.new do |convert|
    convert << "-size" << "#{A4_WIDTH_PX}x#{A4_HEIGHT_PX}"
    convert << "-background" << "white"
    convert << "xc:white"
    
    cards_batch.each_with_index do |card_path, card_index|
      row = card_index / CARDS_PER_ROW
      col = card_index % CARDS_PER_ROW
      
      x = MARGIN_PX + col * (CARD_WIDTH_PX + SPACE_X)
      y = MARGIN_PX + row * (CARD_HEIGHT_PX + SPACE_Y)
      
      convert << "(" << card_path
      convert << "-resize" << "#{CARD_WIDTH_PX}x#{CARD_HEIGHT_PX}!"
      convert << ")"
      convert << "-geometry" << "+#{x}+#{y}"
      convert << "-composite"
    end
    
    convert << "-density" << "300"
    convert << "-colorspace" << "sRGB"
    convert << "-units" << "PixelsPerInch"
    convert << output_filename
  end
end

def create_blank_page
  temp_file = "temp_blank_#{Time.now.to_i}.png"
  
  MiniMagick::Tool::Magick.new do |magick|
    magick << "-size"
    magick << "#{A4_WIDTH_PX}x#{A4_HEIGHT_PX}"
    magick << "-depth"
    magick << "8"
    magick << "-colorspace"
    magick << "sRGB"
    magick << "-type"
    magick << "TrueColor"
    magick << "xc:white"
    magick << temp_file
  end
  
  page = MiniMagick::Image.open(temp_file)
  
  page.colorspace "sRGB"
  page.depth 8
  page.type "TrueColor"
  
  File.delete(temp_file) if File.exist?(temp_file)
  page
end

def add_card_to_page(page, card_path, x, y)
  card = MiniMagick::Image.open(card_path)
  
  card.colorspace "sRGB"
  card.depth 8
  card.type "TrueColor"
  
  card.resize "#{CARD_WIDTH_PX}x#{CARD_HEIGHT_PX}!"
  
  page.colorspace "sRGB"
  page.depth 8
  page.type "TrueColor"
  
  result = page.composite(card) do |c|
    c.compose "Over"
    c.geometry "+#{x}+#{y}"
    c.colorspace "sRGB"
    c.background "#FFD600"
  end
  
  result.colorspace "sRGB"
  result.depth 8
  result.type "TrueColor"
  
  result
end

def save_page_as_pdf(page, filename)
  page.colorspace "sRGB"
  page.depth 8
  page.format 'pdf'
  
  page.density "300"
  page.units "PixelsPerInch"
  
  page.page "#{A4_WIDTH_PX}x#{A4_HEIGHT_PX}"
  
  page.write filename
  
  puts "   💾 Sauvegardé: #{filename}"
end

def merge_series
  puts "🔗 Fusion de tous les rectos avec versos intercalés..."
  
  recto_files = Dir.glob("printing_output/*_recto.pdf").sort
  verso_path = "assets/verso_all_page.pdf"
  
  unless File.exist?(verso_path)
    puts "❌ Fichier verso introuvable: #{verso_path}"
    return
  end
  
  if recto_files.empty?
    puts "❌ Aucun fichier recto trouvé dans printing_output/"
    return
  end
  
  puts "📊 #{recto_files.length} pages recto trouvées"
  puts "📄 Verso utilisé: #{verso_path}"
  
  final_pdf_path = "printing_output/cartes_complete_serie.pdf"

  MiniMagick::Tool::Convert.new do |convert|
    recto_files.each do |recto_file|
      convert << recto_file
      convert << verso_path
      
      puts "   ✅ Ajouté: #{File.basename(recto_file)} + verso"
    end
    
    convert << "-density" << "300"
    convert << "-colorspace" << "sRGB"
    convert << "-compress" << "jpeg"
    convert << "-quality" << "90"
    convert << final_pdf_path
  end
  
  puts "\n🎉 Fusion terminée!"
  puts "📂 Fichier généré: #{final_pdf_path}"
  puts "📖 #{recto_files.length * 2} pages totales (recto + verso alternés)"
  puts "📋 Instructions d'impression:"
  puts "   1. Imprimez toutes les pages du PDF"
  puts "   2. Le recto et verso sont déjà dans le bon ordre"
  puts "   3. Découpez en suivant les marges"
end

# Décommentez la fonction que vous voulez utiliser :

create_printing_serie
merge_series