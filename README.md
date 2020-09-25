# ghcu - Gravio Hub Clean Up
This script cleans up a GHub for additional space. 
Currenty it has the following features:

* HttpRequest Request/Resposne log cleanup (`ghcu.sh -a`)
* Deadweight .tar file removal (`ghcu.sh -r`)
* Docker /tmp folder cleanup (`ghcu.sh -d`)
* Media Data (image only) removal (`ghcu.sh -i`)
* system diagnostic + gravio log compression/removal (`ghcu.sh -l`)

These flags can be combined. For instance: `ghcu.sh -ardil`, or `ghcu.sh -a -r -d -i -l`

For more details usage notes, `ghcu.sh -h` will print the help menu.

# Downloading
File can be downloaded directly onto the GHub computer with the following command:
```bash
wget https://raw.githubusercontent.com/0xNF/ghcu/master/src/ghcu.sh
chmod +x ./ghcu.sh
```

be sure to run the `chmod +x` command on it, otherwise it will not be executable.

# Usage
```bash
./ghcu.sh -h
```
