# iPC VRE DpFrEP Executor

## Requirements

- Python 3.6 or later
- R
- git

```bash
sudo apt update
sudo apt install python3
sudo apt install r-base
sudo apt install git
```

In order to install the Python dependencies you need `pip` and `venv` modules.

```bash
sudo apt install python3-pip python3-venv
```

Install R dependencies:

```bash
cd R
./RDpFrEP.sh
```

## Installation

Directly from GitHub:

```bash
cd $HOME
git clone https://github.com/inab/vre_dpfrep_executor.git
cd vre_dpfrep_executor
```

Create the Python environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade wheel
pip install -r requirements.txt
```

## Run the Wrapper

```bash
./VRE_RUNNER --config tests/basic/config.json --in_metadata tests/basic/in_metadata.json --out_metadata out_metadata.json --log_file VRE_RUNNER.log
```

## License
* © 2020 Barcelona Supercomputing Center (BSC), ES
* © 2020 University of Naples (UNINA), IT

Licensed under the Apache License, version 2.0 <https://www.apache.org/licenses/LICENSE-2.0>, see the file `LICENSE.txt` for details.