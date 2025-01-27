# Minimal Termux System

Minimal Termux System is a lightweight solution that enables an independent SSH daemon (SSHD) running as root on Android. This project provides a simple and secure way to remotely manage your Android device via SSH, independent of other Android applications. It also runs the crond daemon, allowing you to schedule and automate scripting tasks.

## Features

- Lightweight and minimal setup.
- Independent of Termux or other Android applications.
- Configurable SSHD running as `root` on port `28282`.
- Compatible with various Android devices (requires root access).

## Installation

### Prerequisites

1. A rooted Android device.
2. Termux application installed.

### Steps

#### Step 1: Building the Package (from Termux)

1. Open the Termux application.
2. Update the package manager:
   ```sh
   pkg upgrade
   ```
3. Install the required packages:
   ```sh
   pkg install busybox ldd rsync openssh tmux wget
   ```
4. Run the build script to generate the `.tar.gz` package:
   ```sh
   sh build-mini-termux-sys.sh
   ```
   The script will generate the `mini-termux-sys-{yyyymmdd}-{arch}.tar.gz` file in the current directory.

#### Step 2: Installing the Package (as root from Termux or without Termux)

1. Ensure you have the `.tar.gz` package built in Step 1.
2. As the root user, install the package:
   ```sh
   sh install-mini-termux-sys.sh mini-termux-sys-{yyyymmdd}-{arch}.tar.gz
   ```
   Replace `{yyyymmdd}` and `{arch}` with the appropriate values for your package.
3. The installation script will attempt to create and place an auto-boot script in the system.

### Testing the SSHD

1. Start the SSHD manually:
   ```sh
   /system/etc/comtermux/start-minitermuxsys.sh
   ```

2. Connect to your Android device via SSH:
   ```bash
   ssh root@<device-ip> -p 28282
   ```
   - Default username: `root`
   - Default password: `minitermuxsys`

3. (Optional) Change the password:
   ```bash
   passwd
   ```

## File Structure

- `build-mini-termux-sys.sh`: Script to generate the `.tar.gz` package.
- `install-mini-termux-sys.sh`: Script to install the `.tar.gz` package and configure the system.
- `/system/etc/comtermux`: Directory where the minimal Termux system is installed.

## Security Notes

- **Change the default password immediately after installation.**
- The password is stored in `$HOME/.termux_authinfo`. Avoid sharing this file.
- Ensure your Android device's SSH port is only accessible from trusted networks.

## Contributing

Contributions are welcome! If you have suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

Use this project at your own risk. The author is not responsible for any damage caused to your device or data.
