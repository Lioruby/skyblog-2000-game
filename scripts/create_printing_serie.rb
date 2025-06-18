require 'mini_magick'
require 'fileutils'

# Configuration des cartes
CARD_WIDTH_CM = 6.3
CARD_HEIGHT_CM = 8.8

# Conversion cm vers pixels (300 DPI)
DPI = 300
# Utilisons les dimensions réelles des PNG au lieu de forcer un redimensionnement
CARD_WIDTH_PX = 972   # Dimensions réelles des PNG générés
CARD_HEIGHT_PX = 1358 # Dimensions réelles des PNG générés

# Format A4 en pixels (300 DPI)
A4_WIDTH_PX = (21.0 * DPI / 2.54).to_i   # 2480px
A4_HEIGHT_PX = (29.7 * DPI / 2.54).to_i  # 3508px

# Calcul des marges et positions - ajusté pour les vraies dimensions
MARGIN_PX = 60  # Marge pour la découpe
CARDS_PER_ROW = 2  # Seulement 2 cartes par ligne car elles sont plus grandes
CARDS_PER_COL = 2  # Seulement 2 cartes par colonne
CARDS_PER_PAGE = CARDS_PER_ROW * CARDS_PER_COL

# Espacement entre les cartes - recalculé
SPACE_X = (A4_WIDTH_PX - 2 * MARGIN_PX - CARDS_PER_ROW * CARD_WIDTH_PX) / (CARDS_PER_ROW - 1)
SPACE_Y = (A4_HEIGHT_PX - 2 * MARGIN_PX - CARDS_PER_COL * CARD_HEIGHT_PX) / (CARDS_PER_COL - 1)

def create_printing_serie
  puts "🎴 Génération des PDFs d'impression en série..."
  
  card_files = Dir.glob("output/pokemon_card_*.png").sort
  verso_card = Dir.glob("assets/card_verso.png")

  

  
  puts "📊 #{card_files.length} cartes trouvées"
  puts "📐 Format: #{CARD_WIDTH_CM}cm x #{CARD_HEIGHT_CM}cm"
  puts "📄 #{CARDS_PER_PAGE} cartes par page A4"
  
  FileUtils.mkdir_p('printing_output')
  
  card_groups = card_files.each_slice(CARDS_PER_PAGE).to_a

  verso_card_group = verso_card * CARDS_PER_PAGE
  verso_filename = "assets/verso_all_page.pdf"
  create_page_with_convert(verso_card_group, verso_filename)
  
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
  MiniMagick::Tool::Magick.new do |magick|
    magick << "-size" << "#{A4_WIDTH_PX}x#{A4_HEIGHT_PX}"
    magick << "-background" << "white"
    magick << "xc:white"
    
    cards_batch.each_with_index do |card_path, card_index|
      row = card_index / CARDS_PER_ROW
      col = card_index % CARDS_PER_ROW
      
      x = MARGIN_PX + col * (CARD_WIDTH_PX + SPACE_X)
      y = MARGIN_PX + row * (CARD_HEIGHT_PX + SPACE_Y)
      
      magick << "(" << card_path << ")"
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
  
  # Vérifier que qpdf est installé
  unless system("which qpdf > /dev/null 2>&1")
    puts "❌ qpdf n'est pas installé. Installez-le avec: brew install qpdf"
    return
  end
  
  puts "📊 #{recto_files.length} pages recto trouvées"
  puts "📄 Verso utilisé: #{verso_path}"
  
  # Créer le dossier complete_serie
  FileUtils.mkdir_p('complete_serie')
  
  # Diviser les fichiers recto en groupes de 25 (25 recto + 25 verso = 50 pages)
  pages_per_serie = 100  # 25 recto + 25 verso = 50 pages totales
  recto_groups = recto_files.each_slice(pages_per_serie).to_a
  
  puts "📚 #{recto_groups.length} séries à générer (max 50 pages chacune)"
  
  recto_groups.each_with_index do |recto_batch, serie_index|
    serie_number = serie_index + 1
    serie_filename = "complete_serie/serie_#{serie_number}.pdf"
    
    puts "\n🎨 Série #{serie_number}/#{recto_groups.length} (#{recto_batch.length * 2} pages: #{recto_batch.length} recto + #{recto_batch.length} verso)..."

    # Construire la liste des fichiers en intercalant recto et verso
    files_list = []
    recto_batch.each do |recto_file|
      files_list << recto_file
      files_list << verso_path
      puts "   ✅ Ajouté: #{File.basename(recto_file)} + verso"
    end
    
    # Utiliser qpdf pour merger sans perte de qualité
    qpdf_command = "qpdf --empty --pages #{files_list.join(' ')} -- \"#{serie_filename}\""
    
    if system(qpdf_command)
      puts "   💾 Série #{serie_number} sauvegardée avec qpdf: #{serie_filename}"
    else
      puts "   ❌ Erreur lors de la création de la série #{serie_number}"
    end
  end
  
  puts "\n🎉 Fusion par séries terminée avec qpdf!"
  puts "📂 Fichiers générés dans: complete_serie/"
  puts "📊 #{recto_groups.length} fichiers de série créés"
  puts "📖 Maximum 50 pages par fichier (25 recto + 25 verso intercalés)"
  puts "📋 Instructions d'impression:"
  puts "   1. Imprimez chaque série séparément"
  puts "   2. Le recto et verso sont déjà dans le bon ordre"
  puts "   3. Découpez en suivant les marges"
  puts "✨ Note: qpdf préserve parfaitement la qualité originale!"
end

# Décommentez la fonction que vous voulez utiliser :

# create_printing_serie
merge_series