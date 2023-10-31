
namespace eval uuid {

}

proc uuid::get_random_bytes_nix {count {secure False}} {
    if $secure {
        set randFile /dev/random
    } else {
        set randFile /dev/urandom
    }
    set    randDev [open $randFile rb]
    set    random  [read $randDev  $count]
    close  $randDev
    return $random
}

 proc uuid::new {} {
    binary scan   [get_random_bytes_nix 16] H8H4H4H4H12 hex1 hex2 hex3 hex4 hex5
    set    hex3   [string replace $hex3 0 0 4]
    set    oldVal [scan [string index $hex4 0] %x]
    set    newVal [format %X [expr {($oldVal & 3) | 8}]]
    set    hex4   [string replace $hex4 0 0 $newVal]
    string toupper $hex1-$hex2-$hex3-$hex4-$hex5
 }