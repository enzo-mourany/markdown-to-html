#!/bin/bash

# AUTHORS: Durand Mathis, Mourany Enzo
set -o errexit  # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset  # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# Remove src directory if is existing
if [[ -d "src" ]]; then
    rm -r src
fi

# HTML Template Page Generation
mkdir src
echo "<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="date" content="%date-meta%" />
    <title>%title%</title>
  </head>
  <body>
    <p>Date: %date%</p>
    %body%
  </body>
</html>" | tr % $ >"src/template.html"

# Generals variable
EDITOR="code"

# SYNOPSIS
# 	selectEditor
#
# DESCRIPTION
#	Select the editor to use
#
function selectEditor {
    EDITOR="$1"
    if [[ -z "$EDITOR" ]]; then
        if [[ -x /usr/bin/editor ]]; then
            EDITOR=/usr/bin/editor
        elif [[ -x /usr/bin/vi ]]; then
            EDITOR=/usr/bin/vi
        elif [[ -x /usr/bin/nano ]]; then
            EDITOR=/usr/bin/nano
        elif [[ -x /usr/bin/emacs ]]; then
            EDITOR=/usr/bin/emacs
        else
            echo "No editor found"
            exit 1
        fi
    fi
}

# SYNOPSIS
#   Generate a HTML page from a Markdown file.
#
# DESCRIPTION
#   Generate a markdown file which contains the navigation
#
function generateIndexPage {
    echo "---
title: Index
date: September 22, 2020
---
# Blog
## List of articles
" >markdown/index.md
    for file in markdown/*.md; do
        if [[ $file != "index.md" ]]; then
            echo "- [${file%.md}]($file)" >>markdown/index.md
        fi
    done
}

# SYNOPSIS
# 	buildPage
#
# USAGE
#   buildPage <markdown-file>
#
# DESCRIPTION
#	Create an HTML page using a template and fill it with the content of a markdown file
#
# EXAMPLE
#	buildPage test.md
#
function buildPage {
    # Check if the page already exist
    if [[ -f "output/$1.html" ]]; then
        rm "output/$1.html"
    fi
    TEMPLATE="src/template.html"
    TITLE="$1"
    # Title for HTML page (same title that md file but without directory and extension)
    HTMLTITLE=${TITLE##*/}
    HTMLTITLE=${HTMLTITLE%.*}
    # Converting markdown to HTML
    pandoc --standalone --template "$TEMPLATE" "$TITLE" -o output/"$HTMLTITLE".html
    echo "Generation..."
    echo "Page HTML générée"
}

# SYNOPSIS
# 	createDirectory
#
# DESCRIPTION
#	Creates directories with the name markdown and pdf at the start of the script.
#
# EXAMPLE
#	createDirectory
#
function createDirectory {
    mkdir -p markdown/index.md
}

function convertHTMLPageToPDF {
    echo "Convertion de HTML à PDF"
    for file in ls output/*.html; do
        echo "$file"
        # TODO
    done
}

# SYNOPSIS
# 	editPage
#
# DESCRIPTION
#	Edition of a page in markdown
#
# EXAMPLE
#	editPage test.md code
#
function editPage {
    echo "Ouverture de ${EDITOR##*/}..."
    if [ "$1" == null ]; then
        echo "----- Pages Disponibles -----"
        for file in markdown/*.md; do
            file="${file##*/}"
            echo "$file"
        done
        echo "-----------------------------"
        echo "Quelle page souhaites tu modifier ?"
        read -r PAGE
        # Test if anwser is empty
        if [[ -z "$PAGE" ]] || [[ "$PAGE" == "index.md" ]]; then
            # afficher l'erreur sur la sortie d'erreur
            echo "Error: No page selected" >&2
            exit 1
        fi
    else
        PAGE="$1"
    fi
    # Check if PAGE's extension is specified
    if [[ "$PAGE" != *.md ]]; then
        PAGE="$PAGE".md
    fi
    "$EDITOR" markdown/"$PAGE"
    # Build the page after the confirmation of user
    if [ -f markdown/"$PAGE" ]; then
        echo "Veux tu générer la page HTML ? (y/n)"
        read -r answer
        if [ "$answer" = "y" ]; then
            buildPage markdown/"$PAGE"
        fi
    fi
}

# SYNOPSIS
# 	checkIfEditorIsSet
#
# DESCRIPTION
#	Check if the EDITOR variable is set
#
# EXAMPLE
#	checkIfEditorIsSet code
#
function checkIfEditorIsSet {
    EDITOR="$1"
    if [[ -f "/usr/bin/editor" ]]; then
        EDITOR="/usr/bin/editor"
    else
        # Check which editor is available
        for editor in ls /usr/bin/*editor*; do
            if [[ -f "$editor" ]]; then
                EDITOR="$editor"
                break
            fi
        done
    fi
}

# SYNOPSIS
# 	deletePage
#
# DESCRIPTION
#	Delete markdown page
#
# EXAMPLE
#	deletePage test.md
#
function deletePage {
    PAGE="$1"
    # Check if the atribut file is empty
    if [ -z "$PAGE" ]; then
        for file in markdown/*.md; do
            echo "$file"
        done
        echo "Quelle page souhaitez vous supprimer ?"
        read -r PAGE
        # Test if anwser is empty
        if [[ -z "$PAGE" ]] || [[ "$PAGE" == "index.md" ]]; then
            # afficher l'erreur sur la sortie d'erreur
            echo "Error: No page selected" >&2
            exit 1
        fi
    fi
    echo "Est-tu sur de vouloir supprimer $PAGE ? (y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        # Check if PAGE's extension is specified
        if [[ "$PAGE" != *.md ]]; then
            PAGE="$PAGE".md
        fi
        rm markdown/"$PAGE"
        echo "Page supprimée"
    else
        echo "Echec de la suppression"
    fi
}

# SYNOPSIS
# 	listMarkdownPages
#
# DESCRIPTION
#	Display the list of markdown pages
#
function listMarkdownPages {
    if [[ -d "markdown" ]]; then
        echo "Pages markdown :"
        for file in markdown/*.md; do
            echo "- ${file##*/}"
        done
    else
        echo "Il n'y a aucune page markdown"
    fi
}

function visualize {
    xdg-open output/index.html
}

# SYNOPSIS
# 	usage
#
# DESCRIPTION
#	Display the usage of the script
#
function usage {
    echo "Usage: $0 [COMMANDE] [PARAMETRE]"
    echo "  construire                Genere des pages HTML et PDF de tout les fichiers markdown"
    echo "  editer [PAGE]             Modifie une page markdown"
    echo "  supprimer [PAGE]          Supprimer une page markdown"
    echo "  lister                    Liste toutes les pages markdown"
}

function main {
    ACTION="$1"
    PAGE="$2"
    if [ "$ACTION" == "build" ] || [ "$ACTION" == "construire" ]; then
        # Remove output directory if is existing
        if [[ -d "output" ]]; then
            rm -r output
        fi
        # Create ouput directory
        mkdir output
        generateIndexPage
        # Build HTML page for each page in markdown directory
        for page in markdown/*.md; do
            buildPage "$page"
        done
        echo "Pages générées avec succes !"
    elif [[ "$ACTION" == "convert" ]]; then
        convertHTMLPageToPDF
    elif [ "$ACTION" == "edit" ] || [ "$ACTION" == "editer" ]; then
        if [ "$#" == 1 ]; then
            editPage null
        else
            editPage "$2"
        fi
    elif [ "$ACTION" == "delete" ] || [ "$ACTION" == "supprimer" ]; then
        deletePage "$2"
    elif [ "$ACTION" == "list" ] || [ "$ACTION" == "lister" ]; then
        listMarkdownPages
    elif [ "$ACTION" == "visualize" ] || [ "$ACTION" == "visualiser" ]; then
        visualize
    elif [ "$ACTION" == "usage" ] || [ "$ACTION" == "help" ]; then
        usage
    else
        echo "Invalid action"
    fi
}

### Call main function ###
if [[ "$#" == 0 ]]; then
    echo "[ERREUR] 1 action est attendue
Usage : ./blogue.sh COMMANDE [PARAMETRE]"
elif [[ "$#" == 1 ]]; then
    main "$1" null
elif [[ "$#" == 2 ]]; then
    main "$1" "$2"
fi
