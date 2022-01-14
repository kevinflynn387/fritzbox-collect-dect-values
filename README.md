bash-script for collecting temperature and power-consumption values of FritzBox connected DECT-devices 

```
vi get_fritzbox_dect_ain_values.sh
# change settings to your environment
```
Requirements:
- create a dedicated FritzBox User and allow access to read the values via the web-service
```
Create a dedicated user account that you can access the FRITZ!Box and Smart-Home devices:

    1) Login to your FRITZ!Box using your Webbrowser ("fritz.box" or "192.168.178.1" per default)
    2) Click "System" in the FRITZ!Box user interface.
    3) Click "FRITZ!Box Users" in the "System" menu.
    4) Click the "Add User" button.
    5) Enable the option "User account enabled".
    6) Enter a username and password for the user in the corresponding fields.
    7) Enable the option "Smart Home" under "Rights". You can assign additional rights according to your individual needs.
    8) Click "Apply" to save the settings.
    
```
