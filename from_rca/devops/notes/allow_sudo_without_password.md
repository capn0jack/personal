# Prevent prompting for password when using sudo
As root

    visudo

change:

    #Allow members of group sudo to execute any command
    %sudo   ALL=(ALL:ALL) ALL

to:

    #Allow members of group sudo to execute any command
    %sudo   ALL=(ALL:ALL) NOPASSWD: ALL