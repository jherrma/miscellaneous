#!/bin/bash
sudo install rpmfusion-nonfree-release-tainted

sudo dnf groupupdate multimedia
sudo dnf groupupdate sound-and-video
sudo dnf install libdvdcss