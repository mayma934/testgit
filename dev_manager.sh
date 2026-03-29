#!/bin/bash

# =========================================================
# Projet : Gestion d’environnement de développement
# Un seul dépôt Git pour tout le dossier mes_projets
# =========================================================

# -------- Variables globales --------
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)/mes_projets"
REPO_DIR="$BASE_DIR"
LOG_FILE="$BASE_DIR/project.log"

# -------- Création de l'environnement --------
mkdir -p "$BASE_DIR"
touch "$LOG_FILE"

# -------- Initialisation du dépôt Git principal --------
if [ ! -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR" || {
        echo "Erreur : impossible d'accéder à $REPO_DIR."
        exit 1
    }

    git init > /dev/null 2>&1 || {
        echo "Erreur : impossible d'initialiser Git dans $REPO_DIR."
        exit 1
    }
fi

# -------- Fonction création projet --------
create_project() {
    echo "Entrez le nom du projet :"
    read -r project_name

    if [ -z "$project_name" ]; then
        echo "❌ Erreur : le nom du projet ne peut pas être vide."
        return 1
    fi

    project_path="$PROJECT_DIR/$project_name"

    if [ -d "$project_path" ]; then
        echo "❌ Erreur : ce projet existe déjà."
        return 1
    fi

    echo "Choisissez le type de projet :"
    echo "1. Python"
    echo "2. Java"
    echo "3. C++"
    echo "4. Web"
    read -r project_type

    mkdir -p \
        "$project_path/src" \
        "$project_path/docs" \
        "$project_path/tests" \
        "$project_path/assets" \
        "$project_path/lib" \
        "$project_path/config" \
        "$project_path/bin" || {
        echo "❌ Erreur : impossible de créer la structure du projet."
        return 1
    }

    {
        echo "# $project_name"
        echo "Type du projet : $project_type"
    } > "$project_path/README.md"

    # Garder les dossiers vides visibles dans Git
    touch \
        "$project_path/src/.gitkeep" \
        "$project_path/docs/.gitkeep" \
        "$project_path/tests/.gitkeep" \
        "$project_path/assets/.gitkeep" \
        "$project_path/lib/.gitkeep" \
        "$project_path/config/.gitkeep" \
        "$project_path/bin/.gitkeep"

    echo "Projet '$project_name' créé le $(date)" >> "$LOG_FILE"
    echo "✅ Projet créé avec succès dans : $project_path"
    return 0
}

# -------- Fonction affichage menu --------
show_menu() {
    echo "==============================================="
    echo " GESTION D’ENVIRONNEMENT DE DEVELOPPEMENT "
    echo "==============================================="
    echo "1. Créer un nouveau projet"
    echo "2. Lister mes projets"
    echo "3. Supprimer un projet"
    echo "4. Git Status"
    echo "5. Git Add & Commit"
    echo "6. Git Push"
    echo "7. Quitter"
    echo "==============================================="
}

# -------- Fonction lister projets --------
list_projects() {
    echo "Liste des projets :"

    if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR" 2>/dev/null)" ]; then
        echo "Aucun projet trouvé."
    else
        ls -1 "$BASE_DIR"
    fi
}

# -------- Fonction suppression projet --------
delete_project() {
    echo "Entrez le nom du projet à supprimer :"
    read -r project_name

    project_path="$BASE_DIR/$project_name"

    if [ ! -d "$project_path" ]; then
        echo "Erreur : projet introuvable."
        return 1
    fi

    echo "Êtes-vous sûr de vouloir supprimer '$project_name' ? (oui/non)"
    read -r confirmation

    if [ "$confirmation" = "oui" ]; then
        rm -rf "$project_path" || {
            echo "Erreur : impossible de supprimer le projet."
            return 1
        }
        echo "Projet '$project_name' supprimé le $(date)" >> "$LOG_FILE"
        echo "Projet supprimé avec succès."
        return 0
    else
        echo "Suppression annulée."
        return 0
    fi
}

# -------- Fonction Git Status --------
git_status_all() {
    cd "$REPO_DIR" || {
        echo "❌ Erreur : impossible d'accéder au dossier $REPO_DIR"
        return 1
    }

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Erreur : ce dossier n'est pas un dépôt Git."
        return 1
    fi

    echo "📁 Statut Git du dépôt principal : $REPO_DIR"
    git status
}

# -------- Fonction Git Add & Commit --------
git_add_commit() {
    echo "Entrez le message du commit :"
    read -r commit_message

    if [ -z "$commit_message" ]; then
        echo "❌ Erreur : le message du commit ne peut pas être vide."
        return 1
    fi

    cd "$REPO_DIR" || {
        echo "❌ Erreur : impossible d'accéder au dossier $REPO_DIR"
        return 1
    }

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Erreur : ce dossier n'est pas un dépôt Git."
        return 1
    fi

    echo "📁 Dépôt principal : $REPO_DIR"
    echo "➕ Ajout de tous les fichiers et dossiers..."
    git add -A || {
        echo "❌ Erreur pendant git add."
        return 1
    }

    if git diff --cached --quiet; then
        echo "✔️ Aucun changement à commit."
        return 0
    fi

    git commit -m "$commit_message" || {
        echo "❌ Erreur lors du commit."
        return 1
    }

    echo "✅ Commit effectué avec succès."
}

# -------- Fonction Git Push --------
git_push_project() {
    cd "$REPO_DIR" || {
        echo "❌ Erreur : impossible d'accéder au dossier $REPO_DIR"
        return 1
    }

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Erreur : ce dossier n'est pas un dépôt Git."
        return 1
    fi

    if ! git rev-parse HEAD >/dev/null 2>&1; then
        echo "❌ Erreur : aucun commit dans ce dépôt."
        return 1
    fi

    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "❌ Erreur : il reste des modifications non commit."
        echo "Fais d'abord le commit avant le push."
        return 1
    fi

    if git remote get-url origin >/dev/null 2>&1; then
        remote_name="origin"
    else
        remote_name=""
    fi

    if [ -z "$remote_name" ]; then
        echo "🔗 Aucun remote trouvé."
        echo "Entrez l'URL du dépôt distant :"
        read -r repo_url

        if [ -z "$repo_url" ]; then
            echo "❌ Erreur : URL vide."
            return 1
        fi

        git remote add origin "$repo_url" || {
            echo "❌ Erreur : impossible d'ajouter le remote origin."
            return 1
        }

        remote_name="origin"
    fi

    remote_url="$(git remote get-url "$remote_name" 2>/dev/null)"

    if [ -z "$remote_url" ]; then
        echo "❌ Erreur : impossible de récupérer l'URL du remote '$remote_name'."
        return 1
    fi

    echo "🔗 Remote utilisé : $remote_name"
    echo "🌍 URL : $remote_url"

    current_branch="$(git branch --show-current)"

    if [ "$current_branch" != "develop" ]; then
        if git show-ref --verify --quiet refs/heads/develop; then
            echo "🔀 Bascule vers la branche develop..."
            git checkout develop || {
                echo "❌ Impossible de basculer vers develop."
                return 1
            }
        else
            echo "🌱 Création de la branche develop..."
            git checkout -b develop || {
                echo "❌ Impossible de créer la branche develop."
                return 1
            }
        fi
    fi

    echo "🚀 Push vers $remote_name/develop..."
    git push -u "$remote_name" develop || {
        echo "❌ Échec du push."
        return 1
    }

    echo "✅ Push réussi vers develop."
}

# -------- Boucle principale --------
while true
do
    show_menu
    echo "Choisissez une option :"
    read -r choix

    case $choix in
        1) create_project ;;
        2) list_projects ;;
        3) delete_project ;;
        4) git_status_all ;;
        5) git_add_commit ;;
        6) git_push_project ;;
        7) echo "Au revoir !" ; break ;;
        *) echo "Choix invalide" ;;
    esac

    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read -r
done