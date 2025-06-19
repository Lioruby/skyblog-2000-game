require 'mini_magick'
require 'fileutils'

# Configuration des cartes
CARD_WIDTH_CM = 6.3
CARD_HEIGHT_CM = 8.8

# Conversion cm vers pixels (300 DPI)
DPI = 300
CARD_WIDTH_PX = (CARD_WIDTH_CM * DPI / 2.54).to_i 
CARD_HEIGHT_PX = (CARD_HEIGHT_CM * DPI / 2.54).to_i
# Format A4 en pixels (300 DPI)
A4_WIDTH_PX = (21.0 * DPI / 2.54).to_i   # 2480px
A4_HEIGHT_PX = (29.7 * DPI / 2.54).to_i  # 3508px

# Calcul des marges et positions
MARGIN_PX = 60  # Marge pour la découpe
CARDS_PER_ROW = 3
CARDS_PER_COL = 3
CARDS_PER_PAGE = CARDS_PER_ROW * CARDS_PER_COL

# Espacement entre les cartes - recalculé
SPACE_X = (A4_WIDTH_PX - 2 * MARGIN_PX - CARDS_PER_ROW * CARD_WIDTH_PX) / (CARDS_PER_ROW - 1)
SPACE_Y = (A4_HEIGHT_PX - 2 * MARGIN_PX - CARDS_PER_COL * CARD_HEIGHT_PX) / (CARDS_PER_COL - 1)

def create_printing_serie
  puts "🎴 Génération des PDFs d'impression en série..."
  
  recto_card = Dir.glob("assets/rectosoireenavire.png")
  verso_card = Dir.glob("assets/versoinvitationNav.png")

  

  
  puts "📐 Format: #{CARD_WIDTH_CM}cm x #{CARD_HEIGHT_CM}cm"
  puts "📄 #{CARDS_PER_PAGE} cartes par page A4"
  
  FileUtils.mkdir_p('printing_output')
  
  recto_card_group = recto_card * CARDS_PER_PAGE
  verso_card_group = verso_card * CARDS_PER_PAGE
  verso_filename = "assets/after_verso_all_page.pdf"
  create_page_with_convert(verso_card_group, verso_filename)

  recto_filename = "assets/after_recto_all_page.pdf"
  create_page_with_convert(recto_card_group, recto_filename)
  
  puts "📚 1 page à générer"

  
  puts "\n🎉 Génération terminée!"
  puts "📂 Fichiers dans: printing_output/"
  puts "📋 Instructions d'impression:"
  puts "   1. Imprimez d'abord tous les rectos"
  puts "   2. Retournez le papier"
  puts "   3. Imprimez les versos correspondants"
  puts "   4. Découpez en suivant les marges"
end

def create_page_with_convert(cards_batch, output_filename)
  MiniMagick::Tool::Magick.new do |magick|
    magick << "-size" << "#{A4_WIDTH_PX}x#{A4_HEIGHT_PX}"
    magick << "-background" << "white"
    magick << "xc:white"
    
    cards_batch.each_with_index do |card_path, card_index|
      row = card_index / CARDS_PER_ROW
      col = card_index % CARDS_PER_ROW
      
      x = MARGIN_PX + col * (CARD_WIDTH_PX + SPACE_X)
      y = MARGIN_PX + row * (CARD_HEIGHT_PX + SPACE_Y)
      
      magick << "(" << card_path
      magick << "-resize" << "#{CARD_WIDTH_PX}x#{CARD_HEIGHT_PX}!"
      magick << ")"
      magick << "-geometry" << "+#{x}+#{y}"
      magick << "-composite"
    end
    
    # Paramètres de qualité optimisés avec magick moderne
    magick << "-density" << "300"
    magick << "-colorspace" << "sRGB"
    magick << "-units" << "PixelsPerInch"
    magick << "-compress" << "zip"      # Compression sans perte
    magick << "-quality" << "100"       # Qualité maximale
    magick << "-depth" << "8"           # Profondeur de couleur
    magick << "-type" << "TrueColor"    # Type de couleur
    magick << "-alpha" << "remove"      # Supprime le canal alpha pour le PDF
    magick << output_filename
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
  
  # Pas de redimensionnement forcé - garder la qualité originale !
  
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
  puts "🔗 Fusion par séries de 50 pages avec versos intercalés..."
  
  recto_files = "assets/after_recto_all_page.pdf"
  verso_path = "assets/after_verso_all_page.pdf"
  
  # Vérifier que qpdf est installé
  unless system("which qpdf > /dev/null 2>&1")
    puts "❌ qpdf n'est pas installé. Installez-le avec: brew install qpdf"
    return
  end
  
  puts "📊 1 page recto trouvée"
  puts "📄 Verso utilisé: #{verso_path}"
  
  # Créer le dossier complete_serie
  FileUtils.mkdir_p('after_serie')
  
  files_list = []
  
  files_list << recto_files
  files_list << verso_path

  serie_filename = "after_serie/serie_1.pdf"
  
  puts "📚 1 série à générer"
  
  # Utiliser qpdf pour merger sans perte de qualité
  qpdf_command = "qpdf --empty --pages #{files_list.join(' ')} -- \"#{serie_filename}\""
  
  if system(qpdf_command)
    puts "   💾 Série 1 sauvegardée avec qpdf: #{serie_filename}"
  else
    puts "   ❌ Erreur lors de la création de la série 1"
  end
  
  puts "\n🎨 Fusion par séries terminée avec qpdf!"
  puts "📂 Fichiers générés dans: after_serie/"
  puts "📊 1 fichier de série créé"
  puts "📖 Maximum 1 page par fichier"
  puts "📋 Instructions d'impression:"
  puts "   1. Imprimez chaque série séparément"
  puts "   2. Le recto et verso sont déjà dans le bon ordre"
  puts "   3. Découpez en suivant les marges"
  puts "✨ Note: qpdf préserve parfaitement la qualité originale!"
end

# Décommentez la fonction que vous voulez utiliser :
create_printing_serie
merge_series
