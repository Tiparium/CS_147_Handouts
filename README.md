# CS 147 Handouts — Setup Guide

## Setting up the work environment

Dependencies:
- Homebrew Package Manager (Mac only) — required for installing make, useful for installing other packages.
- Apt Package Manager (built into Linux, what you’ll install dependencies with in WSL).
- Docker Desktop (required for all platforms).
- Git (includes Bash as optional additional installation. Do that.).
- Make.
- Bash (preinstalled on macOS and most Linux distros; Windows gets via Git install).
- Visual Studio Code.
- Wavetrace (search for “wavetrace” in VSCode extensions after VSCode is installed).
- Python3 (recommended).

Important Notes:
- If any changes need to be made to the repository, an alert will be sent to all students. Recover the changes with `git pull`.
- If any changes need to be made to the docker containers used in this project, do the above, then re-run `./run setup`. If this fails for any reason, try running `make clean_docker`, and re-run. If this fails, contact the instructor.
- If the installation fails during `./run setup`, run `git pull` and retry.

### Setup (Windows)
Set up WSL (You can skip this if you have already set up WSL)
1. Open Powershell as Administrator.
2. Run: `wsl --install`
3. Reboot (Mandatory).

Open Ubuntu app (Not WSL, Not Ubuntu on Windows).
- NOTE: The Ubuntu app is the terminal you will use to interact with all assignments.
- Assume going forwards that any time you are entering a command, it is in the Ubuntu app.
- Using Powershell, terminal, or Bash may have mixed results.

Enable Docker integration with WSL.
- Install Docker Desktop if you haven’t already.
- In Docker Desktop, navigate to Settings, Resources, WSL integration.
- Enable.

From here, follow the MacOS / Linux setup instructions, using the Ubuntu terminal.

### Setup (MacOS / Linux)
- Ensure you have at minimum 3 Gigabytes free storage.
- Install above dependencies if you haven’t already.
- When installing Docker Desktop, do not use custom installation. Docker container intercommunication assumes the default Docker Desktop path. Custom installations WILL break things.

Run the following in terminal:

Linux / WSL:
```bash
sudo apt update
sudo apt install -y \
git \
make \
python3 \
python3-pip \
ca-certificates \
curl \
zip \
unzip \
tree
```

MacOS:
```bash
brew update
brew install \
git \
make \
python \
ca-certificates \
curl \
zip \
unzip \
tree
```

Clone the Handouts Repo:
```bash
git clone https://github.com/Tiparium/CS_147_Handouts.git
```
Or, if students have ssh configured:
```bash
git clone git@github.com:Tiparium/CS_147_Handouts.git
```

Run `./run setup`
- This will install the verilog toolchain docker image. Note that this step may take some time, and should not be done on a mobile hotspot, as some fairly large files will be downloaded. This includes a self test script to ensure that all programs inside the docker container are configured and running correctly.
- Includes a warning to contact the professor or myself if the docker self test fails.

Install VSCode, if you haven’t already, and install Wavetrace into VSCode.

### Testing the wave visualizer
Run `./run wave_test` at project root to build the wave files.

Locate `mux2_continuous.vcd` and `mux2_rocedural.vcd` in the file tree, open both. Each should look like an empty timeline, with a button in the lower right corner labeled Add Signals.

Click the Add Signals button, and add `a`, `b`, `y`, and `sel` to the waveform. Adjust the zoom of the waveform.

If you see a waveform identical to the example (width may vary based on your zoom level), then your environment is fully set up.

If you do not see the above waveform, ensure you have Wavetrace installed, and try again.
