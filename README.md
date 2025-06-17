# Environnement Ruby

Ce projet contient un petit environnement Ruby avec les outils de base pour le développement.

## Installation

1. Assurez-vous d'avoir Ruby installé (version 3.2.0 recommandée)
2. Installez bundler si ce n'est pas déjà fait :
   ```bash
   gem install bundler
   ```
3. Installez les dépendances :
   ```bash
   bundle install
   ```

## Utilisation

### Exécuter le générateur de chaînes aléatoires

```bash
bundle exec ruby src/generator.rb
```

### Ouvrir une console interactive avec toutes les gems chargées

```bash
bundle exec pry
```

## Gems incluses

- **awesome_print** : Pour un affichage coloré et structuré des objets Ruby
- **pry** : Console interactive améliorée pour le debugging
- **rubocop** : Linter et formateur de code Ruby
- **bundler** : Gestionnaire de dépendances

## Structure du projet

```
.
├── Gemfile              # Dépendances Ruby
├── .ruby-version        # Version Ruby recommandée
├── README.md           # Documentation
└── src/
    └── generator.rb    # Script générateur de chaînes aléatoires
```
