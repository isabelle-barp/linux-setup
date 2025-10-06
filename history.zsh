
    6  vim /etc/mkinitcpio.conf
    7  sudo vim /etc/mkinitcpio.conf
    8  sudo mkinitcpio -P
    9  sudo vim /etc/default/grub
   10  sudo grub-mkconfig -o /boot/grub/grub.cfg
  14  xrandr --output HDMI-0 --mode 7680x2160 --rate 120
  18  cd Code/Personal
  27  rm .bash_logout .bash_profile .bashrc
   42  mv picom.conf ./picom
   63  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
   64  xset s off
   65  xset -dpms
   66  xset dpms force off
   67  cat .zshrc
   82  sudo vim /etc/default/grub
   83  sudo grub-mkconfig -o /boot/grub/grub.cfg
  111  sudo vim /etc/modprobe.d/nvidia.conf
  112  sudo mkinitcpio -P
  187  cd .config/alacritty
  194  vim .config/alacritty/alacritty.toml
  196  vim .zshrc
  197  wal -R
  198  vim .config/picom/picom.conf
  199  vim .config/i3/config
  200  vim .config/alacritty/alacritty.toml
  204  mkdir -p ~/.config/wal/templates
  205  vim .config/wal/templates/colors-alacritty.toml
  222  vim .config/picom/picom.conf
  225  cp /etc/ly/config.ini ~/.config/ly
  28  vim .config/ly/config.ini
  253  vim .config/polybar/config.ini
  256  vim .config/i3/config

  24  sudo systemctl enable docker.service
  525  sudo systemctl enable docker.socket
  30  sudo usermod -aG docker $USER
  16  git config --global core.editor "vim"
 205  sudo mv avahi-discover.desktop avahi-discover.desktop.bkp
 1206  sudo mv rofi-theme-selector.desktop rofi-theme-selector.desktop.bkp
 1207  sudo mv rofi.desktop rofi.desktop.bkp
 1208  sudo vim conky.desktop
 1209  sudo vim conky.desktop conky.desktop.bkp
 1211  sudo mv picom.desktop picom.desktop.bkp
 1212  sudo mv wheelmap-geo-handler.desktop wheelmap-geo-handler.desktop.bkp
 1213  sudo mv org.gnupg.pinentry-qt.desktop org.gnupg.pinentry-qt.desktop.bkp
 1214  sudo mv org.gnupg.pinentry-qt5.desktop org.gnupg.pinentry-qt5.desktop.bkp
 1215  sudo mv openstreetmap-geo-handler.desktop openstreetmap-geo-handler.desktop.bkp
 1216  sudo mv Alacritty.desktop Alacritty.desktop.bkp
 1217  sudo mv bssh.desktop bssh.desktop.bkp
 1218  sudo mv bvnc.desktop bvnc.desktop.bkp
 1219  sudo mv qv4l2.desktop qv4l2.desktop.bkp
 1220  sudo mv qvidcap.desktop qvidcap.desktop.bkp
 1221  sudo mv htop.desktop htop.desktop.bkp
 1222  sudo mv mpv.desktop mpv.desktop.bkp
 224  vim cursor.desktop
 1225  sudo mv electron34.desktop electron34.desktop.bkp
 1226  sudo mv electron37.desktop electron37.desktop.bkp
 1228  mv conky.desktop conky.desktop.bkp
 1229  sudo mv conky.desktop conky.desktop.bkp
 299  sudo mv ranger.desktop ranger.desktop.bkp
 1346  sudo systemctl start bluetooth.service
 1347  sudo systemctl enable bluetooth.service
 350  bluetoothctl