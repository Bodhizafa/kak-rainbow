# Rainbow.kak (C) 2020 Landon Meernik. MIT License.

# Declare a range spec set.
# This holds the actual positions we want to highlight and their colors
declare-option -hidden range-specs rainbow
# Rainbow colors
declare-option str-list rainbow_colors
set-option global rainbow_colors rgb:FFFFFF+b rgb:FF0000 rgb:FFa500 rgb:FFFF00 rgb:00FF00 rgb:0000FF rgb:8B00FF rgb:EE42EE

define-command rainbow-enable-window -docstring "enable rainbow parentheses for this window" %{
    hook -group rainbow window InsertIdle .* %{ rainbow-view }
    hook -group rainbow window NormalIdle .* %{ rainbow-view }
}

define-command rainbow-disable-window -docstring "disable rainbow parentheses for this window" %{
    remove-hooks window rainbow
    remove-highlighter window/rainbow
}

# Does rainbow parens on the current view
define-command -hidden rainbow-view %{
    evaluate-commands -draft -save-regs ^ %{
        try %{
            add-highlighter -override window/rainbow ranges rainbow
        }
        try %{
            set-option window rainbow "%val{timestamp}"
            execute-keys -save-regs _ ' ;Z<ret>' # save original main selection in ^ reg
            execute-keys 'gtGbGls[{}()\[\]]<ret>' # select all rainbowable characters in the curent view
            evaluate-commands -no-hooks %sh{
                # We need to know what selections are, and what they contain collated together
                # so we can emit range specs and know whether each selection is an open or close.
                #
                # This could probably be done faster using bash and process redirection,
                # half the time this script takes to execute on my test dataset is in mkfifo,
                # 
                # To do this, we create two temporary FIFOs and read them with paste,
                # which gives us descs on the same lines as their selection contents.
                # We then use awk to generate the actual range-specs
                SELS_PIPE=$(mktemp -u)
                DESCS_PIPE=$(mktemp -u)
                mkfifo $SELS_PIPE
                mkfifo $DESCS_PIPE
                # descs are in document order, except the main one is first.
                # sels are in document order, so we have to sort descs first to make them match.
                echo $kak_selections_desc | tr ' ' '\n'| sort -V > $DESCS_PIPE &
                echo $kak_selections | tr ' ' '\n' > $SELS_PIPE &
                CURSOR_DESC=$(echo $kak_reg_caret | cut -d' ' -f2)
                export kak_opt_rainbow_colors
                # hehe awk go brrr
                { paste -d' ' $DESCS_PIPE $SELS_PIPE; echo $CURSOR_DESC '!'; } | sort -V | awk '
                BEGIN {
                    FS=" ";
                    n_colors = split(ENVIRON["kak_opt_rainbow_colors"], colors, " ");
                    open_by_close[")"] = "("
                    open_by_close["}"] = "{"
                    open_by_close["]"] = "["
                }
                $2 ~ /[({\[]/ {
                    level = --level_by_open[$2]
                    level_by_idx[NR]=level;
                    descs_by_idx[NR]=$1;
                    open_by_idx[NR]=$2
                }
                $2 ~ /[)}\]]/ {
                    level_by_idx[NR]=level_by_open[open_by_close[$2]]++;
                    descs_by_idx[NR]=$1;
                    open_by_idx[NR]=open_by_close[$2]
                }
                $2 == "!" {
                    for (open in level_by_open) {
                        cursor_level_by_open[open] = level_by_open[open]
                    }
                }
                END {
                    for(idx in descs_by_idx) {
                        final_level=(level_by_idx[idx] - cursor_level_by_open[open_by_idx[idx]]) % n_colors
                        if (final_level >= 0) {
                            print "set-option -add window rainbow " descs_by_idx[idx] "|" colors[final_level + 1];
                        } else {
                            print "set-option -add window rainbow " descs_by_idx[idx] "|" colors[n_colors + final_level + 1]
                        }
                    }
                }
                '
                rm $DESCS_PIPE
                rm $SELS_PIPE
            }
        }
    }
}

