# Find the length of the longest line:

    wc -L slow-2022-02-16.log

# Find the number of the longest line:

    cat -n slow-2022-02-16.log | awk '{print "longest_line_number: " $1 " length_with_line_number: " length}' | sort -k4 -nr | head -3

# Print a specific line number:

    awk '{if(NR==3013) print $0}' slow-2022-02-16.log
