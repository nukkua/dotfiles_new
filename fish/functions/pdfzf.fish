function pdfzf --description "Buscar PDFs con fzf y abrir en zathura"
    if not set -q PDF_SEARCH_DIRS
        echo "Define PDF_SEARCH_DIRS en tu config.fish"
        return 1
    end

    set -l valid_dirs
    for dir in $PDF_SEARCH_DIRS
        if test -d $dir
            set valid_dirs $valid_dirs $dir
        end
    end

    if test (count $valid_dirs) -eq 0
        echo "No hay directorios válidos para buscar PDFs."
        return 1
    end

    set -l selected_pdf (
        find $valid_dirs -type f -iname "*.pdf" 2>/dev/null \
        | sort \
        | fzf --prompt="PDF > " --height=80% --layout=reverse --border
    )

    test -n "$selected_pdf"; and zathura "$selected_pdf" >/dev/null 2>&1 & disown
end
