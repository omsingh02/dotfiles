#!/bin/sh

file="$1"
# If lf doesn't provide width/height (e.g., running manually), default to 80x25
w="${2:-80}"
h="${3:-25}"
x="${4:-0}"
y="${5:-0}"

case "$(file -Lb --mime-type -- "$file")" in
    # --- 1. IMAGES ---
    image/*)
        chafa -f sixel -s "${w}x${h}" --animate off --polite on "$file"
        # The 'exit 1' prevents lf from caching Sixel data as text.
        exit 1 
        ;;

    # --- 2. PDFs ---
    application/pdf)
        CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lf"
        mkdir -p "$CACHE"
        
        # Create a unique thumbnail name based on the file path to avoid overwriting
        THUMB="$CACHE/$(echo "$file" | md5sum | awk '{print $1}').jpg"
        
        # Generate the thumbnail if it doesn't already exist
        if [ ! -f "$THUMB" ]; then
            pdftoppm -jpeg -f 1 -singlefile "$file" "${THUMB%.*}"
        fi
        
        # Display the generated thumbnail using chafa
        chafa -f sixel -s "${w}x${h}" --animate off --polite on "$THUMB"
        exit 1
        ;;

    # --- 3. ARCHIVES ---
    application/zip|application/x-tar|application/x-gzip|application/x-bzip2|application/x-xz|application/x-zstd)
        bsdtar -tf "$file"
        ;;

    # --- 4. TEXT & CODE ---
    text/*|application/json|inode/x-empty)
        # bat automatically highlights code based on the extension
        bat --force-colorization --paging=never --style=plain --terminal-width $(($w - 3)) "$file"
        ;;

    # --- 5. FALLBACK ---
    *)
        # For completely unknown binary files, just print file info
        file -b "$file"
        ;;
esac
