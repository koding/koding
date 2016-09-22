#!/bin/bash

# Koding Service Connector Installer.
# Copyright (C) 2012-2016 Koding Inc., all rights reserved.

is_macosx=$(uname -v | grep -Ec '^Darwin Kernel.*')
init_tool=
init_dir=
init_file=

alias curl='curl -L --retry 5 --retry-delay 0'

get_init_tool() {
	for tool in update-rc.d chkconfig launchctl; do
		if sudo which ${tool} &>/dev/null; then
			echo ${tool}
			break
		fi
	done
}

get_init_dir() {
	local dirs=( /etc/init.d /etc/rc.d/init.d /etc/rc.d )
	if [ ${is_macosx} -eq 1 ]; then
		echo "/Library/LaunchDaemons"
	fi
	for dir in ${dirs[@]}; do
		if [[ -d ${dir} ]]; then
			echo ${dir}
		fi
	done
}

get_init_file() {
	case "${init_tool}" in
		launchctl)
			echo "${init_dir}/klient.plist"
			;;
		*)
			echo "${init_dir}/klient"
			;;
	esac
}

get_start_klient_command() {
	case "${init_tool}" in
		update-rc.d)
			echo "${init_file} start"
			;;
		chkconfig)
			echo "service klient start"
			;;
		launchctl)
			echo "launchctl load -w ${init_file}"
			;;
		*)
			;;
	esac
}

get_stop_klient_command() {
	case "${init_tool}" in
		update-rc.d)
			echo "${init_file} stop"
			;;
		chkconfig)
			echo "service klient stop"
			;;
		launchctl)
			echo "launchctl unload -w ${init_file}"
			;;
		*)
			;;
	esac
}

does_service_exist() {
	case "${init_tool}" in
		update-rc.d)
			[[ $(sudo update-rc.d -n -f "klient" remove 2>&1 | grep -c /etc) -ge 2 ]] && return 0
			;;
		chkconfig)
			sudo chkconfig --list "klient" &>/dev/null && return 0
			;;
		launchctl)
			sudo launchctl list "klient" &>/dev/null && return 0
			;;
		*)
			;;
	esac
	return 1
}

stop_klient() {
	if [ ${is_macosx} -eq 1 ]; then
		# try to stop old klient.plist
		sudo launchctl unload -w "${init_dir}/com.koding.klient.plist" &>/dev/null && rm -v "${init_dir}/com.koding.klient.plist" || true
	else
		# try to stop old upstart klient
		sudo stop klient &>/dev/null || true
	fi

	eval sudo $(get_stop_klient_command) &>/dev/null || true
}

install_service() {
	case "${init_tool}" in
		update-rc.d)
			sudo update-rc.d -f "klient" defaults && return 0
			;;
		chkconfig)
			sudo chkconfig --add "klient" &>/dev/null && return 0
			;;
		launchctl)
			[[ -f "${init_file}" ]] && return 0
			;;
		*)
			;;
	esac
	return 1
}

# remove_service
remove_service() {
	case "${init_tool}" in
			update-rc.d)
				sudo update-rc.d -f "klient" remove &>/dev/null && return 0
				;;
			chkconfig)
				sudo chkconfig --del "klient" &>/dev/null && return 0
				;;
			launchctl)
				sudo rm -f "${init_file}" &>/dev/null && return 0
				;;
			*)
				;;
	esac
	return 1
}

download_klient() {
	KONTROLURL=${KONTROLURL:-https://koding.com/kontrol/kite}
	CHANNEL=${CHANNEL:-managed}
	VERSION=$(curl -sSL https://koding-klient.s3.amazonaws.com/${CHANNEL}/latest-version.txt)

	sudo mkdir -p /opt/kite/klient
	[[ -n "$USER" ]] && sudo chown -R "$USER" /opt/kite || true

	cat << EOF
Downloading Koding Service Connector 0.1.${VERSION}...

EOF
	if [[ ${is_macosx} -eq 1 ]]; then
		LATESTURL="https://koding-klient.s3.amazonaws.com/${CHANNEL}/${VERSION}/klient-0.1.${VERSION}.darwin_amd64.gz"

		if ! sudo curl -sSL $LATESTURL -o /opt/kite/klient/klient.gz; then
			cat << EOF
Error: Unable to download or save Koding Service Connector
package.
EOF
			return 1
		fi

		if ! sudo gzip -d -f /opt/kite/klient/klient.gz; then
			echo "Error: Failed to install Koding Service Connector package" 2>&1
			return 1
		fi

		sudo chmod 0755 /opt/kite/klient/klient

		return 0
	fi

	LATESTURL="https://koding-klient.s3.amazonaws.com/${CHANNEL}/${VERSION}/klient_0.1.${VERSION}_${CHANNEL}_amd64.deb"

	if ! curl -sSL $LATESTURL -o klient.deb; then
		cat << EOF
Error: Unable to download or save Koding Service Connector
package.
EOF
		return 1
	fi

	cat << EOF
Installing the Koding Service Connector package...
EOF
	if ! sudo dpkg -i --force-confnew klient.deb > /dev/null; then
		echo "Error: Failed to install Koding Service Connector package" 2>&1
		return 1
	fi

	# Clean the klient deb from the system
	rm -f klient.deb

	return 0
}

# do_install_klient <KONTROLURL> <KITE_USERNAME>
do_install_klient() {
	local kontrolurl=${1:-https://koding.com/kontrol/kite}
	local username=${2:-}

	if does_service_exist; then
		if ! remove_service; then
			cat <<EOF
Unable to remove existing klient service. Please remove it manually and retry.
EOF
			return 1
		fi
	fi

	if [[ ${is_macosx} -eq 1 ]]; then
		cat <<EOF | sudo tee /opt/kite/klient/klient.sh &>/dev/null
#!/bin/bash

# Koding Service Connector
# Copyright (C) 2012-2016 Koding Inc., all rights reserved.

# wait till network is ready

. /etc/bashrc
. /etc/profile
. /etc/rc.common

CheckForNetwork

while [ "\${NETWORKUP}" != "-YES-" ]; do
	sleep 5
	NETWORKUP=
	CheckForNetwork
done

# start klient

export HOME=\$(eval cd ~\${USERNAME}; pwd)
export KITE_KONTROL_URL=\${KITE_KONTROL_URL:-https://koding.com/kontrol/kite}
export PATH=\$PATH:/usr/local/bin

ulimit -n 5000
sudo -E -u "\$USERNAME" /opt/kite/klient/klient"
EOF
		cat <<EOF | sudo tee /opt/kite/klient/klient.init &>/dev/null
<!--
Koding Service Connector
Copyright (C) 2012-2016 Koding Inc., all rights reserved.
-->

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>klient</string>

	<key>WorkingDirectory</key>
	<string>/opt/kite/klient</string>

	<key>StandardErrorPath</key>
	<string>/Library/Logs/klient.log</string>

	<key>StandardOutPath</key>
	<string>/Library/Logs/klient.log</string>

	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>

	<key>EnvironmentVariables</key>
	<dict>
			<key>USERNAME</key>
			<string>$(whoami)</string>
			<key>KITE_USERNAME</key>
			<string>${username}</string>
			<key>KITE_KONTROL_URL</key>
			<string>${kontrolurl}</string>
			<key>KITE_HOME</key>
			<string>/etc/kite</string>
	</dict>

	<key>ProgramArguments</key>
	<array>
			<string>/bin/bash</string>
			<string>-c</string>
			<string>/opt/kite/klient/klient.sh</string>
	</array>
</dict>
</plist>
EOF

		sudo chmod +x  /opt/kite/klient/klient.sh
	fi

	sudo cp -f /opt/kite/klient/klient.init "${init_file}"

	if [[ ${is_macosx} -eq 1 ]]; then
		sudo sed -i "" -e "s|\%USERNAME\%|$(whoami)|g" "${init_file}"
		sudo sed -i "" -e "s|\%START_COMMAND\%|/opt/kite/klient/klient -kontrol-url ${kontrolurl}|g" "${init_file}"
	else
		sudo sed -i -e "s|\%USERNAME\%|$(whoami)|g" "${init_file}"
		sudo sed -i -e "s|\%START_COMMAND\%|/opt/kite/klient/klient -kontrol-url ${kontrolurl}|g" "${init_file}"
	fi

	if ! install_service; then
		cat <<EOF
Unable to install klient service. Please retry installation.
EOF
		return 1
	fi

	return 0
}

do_install_screen() {
	if ! which screen &>/dev/null; then
		if [[ ${is_macosx} -eq 1 ]]; then
			# screen from homebrew is not compatible with klient
			cat <<EOF
Error: The Unix command 'screen' must be installed prior to installing
the Koding Service connector. Please install it, and retry this
installation.
EOF
			return 1
		fi

		# If apt-get is not available, inform the user to install screen
		# themselves.
		if ! which apt-get &>/dev/null; then
			cat << EOF
Error: The Unix command 'screen' must be installed prior to installing
the Koding Service connector. Please install it, and retry this
installation.
EOF
			exit 1
		fi

		echo "Installing Screen..."

		# The `<&-` is used because .. i think, apt-get is swallowing
		# stdin for some odd reason. Which would then cause the pipe to break
		# and the entire rest of the script would just be printed.
		#
		# The only way i even figured it out, was
		# via: http://unix.stackexchange.com/a/182625
		# Unfortunately i have no more information on that.
		sudo apt-get install -qq -y screen <&-
	fi

	return 0
}

init() {
	export init_tool=$(get_init_tool)
	export init_dir=$(get_init_dir)
	export init_file=$(get_init_file)
}

main() {
	echo "Testing sudo permissions, please input password if prompted..."
	if ! sudo -l &>/dev/null; then
		cat << EOF
Error: Sudo (root) permission is required to install the Koding Service
Connector Please run this command from a Linux Account on this machine
with proper permissions.
EOF
		exit $err
	fi

	init

	if ! do_install_screen; then
		exit 2
	fi

	local routeErr=0
	if ! sudo route del -host 169.254.169.254 reject 2> /dev/null; then
		routeErr=$?
	fi

	awsApiResponse=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document --max-time 5 2> /dev/null || true)

	if [ "$routeErr" -eq 0 ]; then
		sudo route add -host 169.254.169.254 reject 2> /dev/null || true
	fi

	if [[ $awsApiResponse == *"614068383889"* ]]; then
		cat << EOF
Error: This feature is for non-Koding machines
EOF
		exit 1
	fi

	pushd /tmp &>/dev/null

	stop_klient

	if ! download_klient; then
		exit 2
	fi

	popd &>/dev/null

	# Using an extra newline at the end of this message, because Klient
	# might need to communicate with the user - so the extra line helps any
	# klient prompts stand out.
	cat << EOF
Authenticating you to the Koding Service

EOF

	export KITE_USERNAME=${2:-}
	export KONTROLURL=${KONTROLURL:-https://koding.com/kontrol/kite}

	if ! do_install_klient "$KONTROLURL" "$KITE_USERNAME"; then
		exit 2
	fi

	# ensure klient is stopped after installing the deb
	stop_klient

	# It's ok $1 to be empty, in that case it'll try to register via password input
	if ! sudo -E /opt/kite/klient/klient -register -kite-home "/etc/kite" --kontrol-url "$KONTROLURL" -token "${1:-}" -username "$KITE_USERNAME" < /dev/tty; then
		cat << EOF
$err: Service failed to register with Koding. If this continues to happen,
please contact support@koding.com
EOF
		exit $err
	fi


	if sudo [ ! -f /etc/kite/kite.key ]; then
		echo "Error: Critical component missing. Aborting installation."
		exit -1
	fi

	sudo chmod 755 /etc/kite
	sudo chmod 755 /etc/init.d/klient 2>&/dev/null || true
	sudo chmod 644 /etc/kite/kite.key

	cat << EOF
Starting the Koding Service Connector...

EOF

	if ! eval sudo $(get_start_klient_command); then
		cat <<EOF
Failed to start Koding Service Connector. Please reinstall the service and retry.
EOF
		exit 2
	fi

	# TODO: Confirm that klient is running, before displaying success message
	# to user. (Trying to find the best method for confirming this, rather
	# than just grepping)

	# Print user friendly message.
	cat << EOF



>>>>>>>>>>>>>>>Success!<<<<<<<<<<<<<<

This machine has been successfully connected to Koding and
should show up automatically on the sidebar of your Koding account
where your other machines are listed.

Please head over to koding.com now and remember to not close
the "Add Your Own Machine" dialogue box until you see this machine appear
in the sidebar.

For some reason if this machine does not show up on your koding account
in the next 2-3 minutes, please re-run the install script or contact us
at support@koding.com.
EOF

exit 0
}

main $*
