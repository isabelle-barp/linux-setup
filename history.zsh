
    6  vim /etc/mkinitcpio.conf
    7  sudo vim /etc/mkinitcpio.conf
    8  sudo mkinitcpio -P
    9  sudo vim /etc/default/grub
   10  sudo grub-mkconfig -o /boot/grub/grub.cfg
  14  xrandr --output HDMI-0 --mode 7680x2160 --rate 120
  18  cd Code/Personal
   63  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
   64  xset s off
   65  xset -dpms
   66  xset dpms force off
   67  cat .zshrc
   82  sudo vim /etc/default/grub
   83  sudo grub-mkconfig -o /boot/grub/grub.cfg
  111  sudo vim /etc/modprobe.d/nvidia.conf
  225  cp /etc/ly/config.ini ~/.config/ly