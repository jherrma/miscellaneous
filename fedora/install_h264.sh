#!/bin/bash
sudo dnf config-manager --set-enabled fedora-cisco-openh264
sudo dnf install gstreamer1-plugin-openh264 mozilla-openh264